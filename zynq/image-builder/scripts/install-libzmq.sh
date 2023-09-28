#!/bin/sh

cd /opt
git clone https://github.com/zeromq/libzmq.git
cd libzmq
mkdir build ; cd build
cmake .. -DWITH_TLS=no
make -j4 install

cd /opt
git clone https://github.com/zeromq/cppzmq.git
cd cppzmq
mkdir build ; cd build
cmake .. -DCPPZMQ_BUILD_TESTS=no
make -j4 install

/usr/sbin/ldconfig
