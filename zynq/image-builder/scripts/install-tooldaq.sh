#!/bin/sh

cd /opt
git clone https://github.com/ToolFramework/ToolFrameworkCore.git
cd ToolFrameworkCore
make clean
make -j4 

cd /opt
git clone https://github.com/ToolDAQ/ToolDAQFramework.git
cd ToolDAQFramework
make clean
make -j4

cd /opt
git clone https://github.com/ToolDAQ/libDAQInterface.git
cd libDAQInterface
mkdir Dependencies
ln -s /opt/ToolFrameworkCore Dependencies/
ln -s /opt/ToolDAQFramework Dependencies/
make clean
make -j4

cd /opt
git clone https://github.com/gtortone/mpmt-tooldaq.git
cd mpmt-tooldaq
mkdir build
cd build
cmake ..
make -j4
