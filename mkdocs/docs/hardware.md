
# Hardware specification

## SAMA

* ARM Cortex-A5 Processor-based SAMA5D27 MPU
* 128MB DDR2 SDRAM
* 8MB Serial Quad I/O Flash Memory (SST26VF064BT-104I/MF)
* 256 bytes Serial EEPROM with EUI-48 Node Identity (24AA02E48T-I/OT)
* 10Base-T/100Base-TX Ethernet PHY (KSZ8081RNAIA)
* 103 I/Os
* 1 USB Device, 1 USB Host and 1 HSIC Interface

## Zynq 7000

* ARMv7 Processor single core
* 512MB RAM
* 32MB Serial Quad I/O Flash Memory
* 8GB eMMC
* 10Base-T/100Base-TX Ethernet

## On-board connectors

| Name | Description                          |
| ----------- | ------------------------------------ |
| `JDEB1`     | UART0 from ATSAMA5D27  |
| `JSAMA1`    | USB connection for SAM-BA programmer/debugger |

## On-board jumpers

| Name | Description   | 1-2 closed | 2-3 closed |
| ----------- | -------|------------|------------|
| `JT3`    | SAMA eMMC enable | external eMMC enabled | external eMMC disabled |
| `JT4`    | QSPI boot enable | QSPI boot enabled | QSPI boot disabled |

## Communication bus

``` mermaid
graph LR
  A[SAMA] <--> |USB| B[FTDI];
  B <--> |FIFO| C[Zynq];
  B <--> |JTAG| C;
  A <--> |UART| C;
  A <--> |UART| C;
```

### JTAG
SAMA is JTAG master and Zynq is a JTAG target using FTDI USB controller.

### UART
Two different UART are available between SAMA and Zynq. They makes available Linux login console from Zynq to SAMA and from SAMA to Zynq.

### FIFO
A FIFO interface is available between Zynq and FTDI to offer a backup solution for data acquisition where Zynq can fill FTDI FIFO and SAMA can fetch data using USB protocol.

