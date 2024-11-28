#!/bin/sh

mkdir -p /opt/packages
cd /opt/packages

git clone https://github.com/3cky/mbusd.git

cd mbusd

mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
make install


