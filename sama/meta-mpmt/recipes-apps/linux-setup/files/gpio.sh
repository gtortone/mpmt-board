#!/usr/bin/env sh

function ftdi {
   if [[ -z "$1" ]]; then
      echo "ftdi: 0/disable 1/enable"
      return
   fi

   if [ "$1" = "0" -o "$1" = "1" ]; then
      echo 16 > /sys/class/gpio/export 2>/dev/null
      echo out > /sys/class/gpio/PA16/direction
      echo $1 > /sys/class/gpio/PA16/value
      echo 16 > /sys/class/gpio/unexport 2>/dev/null
      echo "OK"
      return
   fi

   echo "ftdi: 0/disable 1/enable"
}

function jtag {
   if [[ -z "$1" ]]; then
      echo "jtag: 0/disable 1/enable"
      return
   fi

   if [ "$1" = "0" -o "$1" = "1" ]; then
      echo 52 > /sys/class/gpio/export 2>/dev/null
      echo out > /sys/class/gpio/PB20/direction
      echo $1 > /sys/class/gpio/PB20/value
      echo 52 > /sys/class/gpio/unexport 2>/dev/null
      echo "OK"
      return
   fi

   echo "jtag: 0/disable 1/enable"
}

function fpga {
   if [[ -z "$1" ]]; then
      echo "fpga: r/reset"
      return
   fi

   if [ "$1" = "r" ]; then
      echo 48 > /sys/class/gpio/export 2>/dev/null
      echo out > /sys/class/gpio/PB16/direction
      echo 0 > /sys/class/gpio/PB16/value
      sleep 1
      echo 1 > /sys/class/gpio/PB16/value
      echo 48 > /sys/class/gpio/unexport
      echo "OK"
      return
   fi

   echo "fpga: r/reset"
}
