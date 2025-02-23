#!/bin/sh

mkdir -p /opt/packages
cd /opt/packages

git clone https://bitbucket.org/tmidas/midas --recurse-submodules

cd midas

# 15.11.2024 workaround for MSCB build error
rm -rf mscb
git clone https://bitbucket.org/tmidas/mscb --recurse-submodules

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/opt/midas ..
make -j
make install

# install Python modules
pip3 install -e /opt/packages/midas/python --user --break-system-packages
