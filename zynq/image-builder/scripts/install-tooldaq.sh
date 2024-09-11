#!/bin/sh

cd /opt
#git clone --branch v2.3.0 https://github.com/ToolFramework/ToolFrameworkCore.git
git clone https://github.com/ToolFramework/ToolFrameworkCore.git
cd ToolFrameworkCore
make clean
make -j4 

cd /opt
#git clone --branch v2.3.0 https://github.com/ToolDAQ/ToolDAQFramework.git
git clone https://github.com/ToolDAQ/ToolDAQFramework.git
cd ToolDAQFramework
make clean
make -j4

