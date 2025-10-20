#!/bin/bash

source /usr/bin/gpio.sh

ftdi 1

# wait for FTDI
sleep 1

openocd -f zynq-mpmt.cfg -f init.cfg &&  openocd -f zynq-mpmt.cfg -f load-u-boot.cfg
