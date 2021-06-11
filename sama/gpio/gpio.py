#!/usr/bin/python3

import sys
import time
import gpiod

pin = {}
pin['ftdi'] = 'PA16'
pin['fpga'] = 'PB16'
pin['jtag'] = 'PB20'

cmd = {}
cmd['ftdi'] = ['enable', 'disable']
cmd['fpga'] = ['reset']
cmd['jtag'] = ['enable', 'disable']

if len(sys.argv) > 2:
    device = sys.argv[1]
    command = sys.argv[2]
else:
    print('Usage: gpio <device> <command>')
    print('device: ftdi - commands: enable/disable')
    print('device: jtag - commands: enable/disable')
    print('device: fpga - command: reset')
    sys.exit()

if (cmd.get(device) is None):
    print(f'E: device {device} not found')
    sys.exit(-1)

cmdList = cmd.get(device)
if (command not in cmdList):
    print(f'E: command {command} not found for device {device}')
    sys.exit(-1)

chip = gpiod.Chip('gpiochip0', gpiod.Chip.OPEN_BY_NAME)

pinName = pin.get(device);
line = chip.find_line(pinName)

if (line is None):
    print(f'E: gpio pin {pinName} not found')
    sys.exit(-1)

line.request(consumer='foobar', type=gpiod.LINE_REQ_DIR_OUT)

if (command == 'enable'):
    line.set_value(1)
elif (command == 'disable'):
    line.set_value(0)
elif (command == 'reset'):
    line.set_value(1)
    time.sleep(0.2)
    line.set_value(0)

print('OK')

chip.close()
