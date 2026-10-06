#!/bin/sh

mkdir -p /opt/packages
cd /opt/packages

git clone https://github.com/3cky/mbusd.git

cd mbusd

cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DSYSTEMD_SERVICES_INSTALL_DIR=/etc/systemd/system
make -j -C build 
make -C build install


