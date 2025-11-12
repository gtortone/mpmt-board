import socket
import json
import mmap
import os
import sys
import math
import time
import subprocess
import threading
import signal

# --- Register access and logic from rc.py ---

from collections import deque

class RunControl:
    _process = None
    _process_lock = threading.Lock()
    _log_buffer = deque(maxlen=100)
    _log_thread = None
    _log_thread_stop = threading.Event()
    def __init__(self):
        try:
            self.fid = open('/dev/uio0', 'r+b', 0)
        except FileNotFoundError:
            print("UIO device not found", file=sys.stderr)
            sys.exit(-1)
        self.regs = mmap.mmap(self.fid.fileno(), 0x10000)
        # Lock to synchronize concurrent register access across clients
        self._reg_lock = threading.Lock()

    def read_reg(self, add):
        # Synchronize access to memory-mapped registers
        with self._reg_lock:
            return int.from_bytes(self.regs[add*4:(add*4)+4], byteorder='little')

    def write_reg(self, add, value):
        # Synchronize access to memory-mapped registers
        with self._reg_lock:
            self.regs[add*4:(add*4)+4] = int.to_bytes(value, 4, byteorder='little')

    def checkRange(self, value, minVal, maxVal):
        return minVal <= value <= maxVal

    # Example: implement a few commands. Add more as needed.
    def cmd_read(self, args):
        # args: {"address": int}
        try:
            address = int(args['address'])
            value = self.read_reg(address)
            return {"status": "ok", "value": value}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def cmd_write(self, args):
        # args: {"address": int, "value": int}
        try:
            address = int(args['address'])
            value = int(args['value'])
            self.write_reg(address, value)
            return {"status": "ok"}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def cmd_status(self, args):
        # Example: return a summary status
        try:
            ch_en_reg = format(self.read_reg(0), '019b')
            pow_en_reg = format(self.read_reg(1), '019b')
            ratemeters = [self.read_reg(i) for i in range(8, 27)]
            deadtime = round((65535 - self.read_reg(27))/65535*100)
            return {
                "status": "ok",
                "channels_enabled": ch_en_reg,
                "power_enabled": pow_en_reg,
                "ratemeters": ratemeters,
                "deadtime": deadtime
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

    # Add more command handlers as needed, following the above pattern.

    def _log_reader(self, proc):
        """Background thread to read process output and store last 100 lines."""
        def read_stream(stream, tag):
            while not self._log_thread_stop.is_set():
                line = stream.readline()
                if not line:
                    break
                text = line.rstrip()
                self._log_buffer.append(f"[{tag}] {text}")
        threads = []
        for stream, tag in ((proc.stdout, 'stdout'), (proc.stderr, 'stderr')):
            t = threading.Thread(target=read_stream, args=(stream, tag), daemon=True)
            t.start()
            threads.append(t)
        for t in threads:
            t.join()

    def cmd_start_process(self, args):
        """
        args: {
            "path": str,  # path to executable
            "params": list[str]  # list of parameters (optional)
        }
        """
        with self._process_lock:
            if self._process is not None and self._process.poll() is None:
                return {"status": "error", "error": "Process already running"}
            path = args.get("path")
            params = args.get("params", [])
            if not path:
                return {"status": "error", "error": "Missing 'path' argument"}
            try:
                self._log_buffer.clear()
                self._log_thread_stop.clear()
                self._process = subprocess.Popen(
                    [path] + params,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    close_fds=os.name != 'nt'
                )
                self._log_thread = threading.Thread(target=self._log_reader, args=(self._process,), daemon=True)
                self._log_thread.start()
                return {"status": "ok", "pid": self._process.pid}
            except Exception as e:
                return {"status": "error", "error": str(e)}

    def cmd_stop_process(self, args):
        """
        args: {}
        """
        with self._process_lock:
            if self._process is None or self._process.poll() is not None:
                return {"status": "error", "error": "No process running"}
            try:
                # Send SIGINT (Ctrl-C)
                self._process.send_signal(signal.CTRL_C_EVENT if os.name == 'nt' else signal.SIGINT)
                try:
                    self._process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    self._process.kill()
                    return {"status": "error", "error": "Process did not terminate, killed"}
                self._log_thread_stop.set()
                if self._log_thread:
                    self._log_thread.join(timeout=2)
                return {"status": "ok", "message": "Process stopped"}
            except Exception as e:
                return {"status": "error", "error": str(e)}
            
    def cmd_process_status(self, args):
        """
        args: {}
        """
        with self._process_lock:
            if self._process is None:
                return {"status": "ok", "running": False, "pid": 0}
            running = self._process.poll() is None
            return {"status": "ok", "running": running, "pid": self._process.pid if running else 0}

    def cmd_log(self, args):
        """Return last 100 lines of process log (stdout/stderr)."""
        with self._process_lock:
            log = list(self._log_buffer)
            self._log_buffer.clear()
        return {"status": "ok", "log":  log}

# --- TCP Server ---

def handle_client(conn, rc):
    with conn:
        file = conn.makefile('rwb')
        while True:
            line = file.readline()
            if not line:
                break
            try:
                req = json.loads(line.decode('utf-8'))
                cmd = req.get('command')
                args = req.get('args', {})
                if not hasattr(rc, f'cmd_{cmd}'):
                    resp = {"status": "error", "error": f"Unknown command: {cmd}"}
                else:
                    resp = getattr(rc, f'cmd_{cmd}')(args)
            except Exception as e:
                resp = {"status": "error", "error": str(e)}
            file.write((json.dumps(resp) + '\n').encode('utf-8'))
            file.flush()

def main():
    HOST = '0.0.0.0'
    PORT = 9000
    rc = RunControl()
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        # Allow a backlog of pending connections
        s.listen(16)
        print(f"RunControl TCP server listening on {HOST}:{PORT}")
        while True:
            conn, addr = s.accept()
            print(f"Connected by {addr}")
            # Serve each client in its own thread to support multiple clients concurrently
            t = threading.Thread(target=handle_client, args=(conn, rc), daemon=True)
            t.start()

if __name__ == '__main__':
    main()
