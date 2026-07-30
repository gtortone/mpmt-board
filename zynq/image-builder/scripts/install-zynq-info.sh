
#!/bin/sh

cd /opt
git clone https://github.com/gtortone/zynq-info.git 

cd /opt/zynq-info
cmake -B build

make -j -C build

cp build/zynq_clkinfo /usr/bin
cp build/zynq_l2info /usr/bin

rm -rf /opt/zynq-info

