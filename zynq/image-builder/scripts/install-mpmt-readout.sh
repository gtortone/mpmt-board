
#!/bin/sh

cd /opt
git clone https://github.com/gtortone/mpmt-readout.git

cd /opt/mpmt-readout
mkdir build && cd build
cmake ..

make -j


