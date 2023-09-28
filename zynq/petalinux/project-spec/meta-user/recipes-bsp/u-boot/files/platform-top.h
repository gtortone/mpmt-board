
#include <configs/platform-auto.h>
#define CONFIG_SYS_BOOTM_LEN 0xF000000

// disable default configuration of 'serverip' environment variable
#undef CONFIG_BOOTP_SERVERIP

#define CONFIG_EXTRA_ENV_SETTINGS \
	SERIAL_MULTI \
	CONSOLE_ARG \
	PSSERIAL0 \
	"autoload=no\0" \ 
	"nc=setenv stdout nc;setenv stdin nc;\0" \
	"bootdelay=5\0" \
	"preboot=run readmac buildmac\0" \
	"ethprime=ethernet@e000b000\0" \
	"readmac=i2c dev 0; i2c read 50 FA.1 6 0xFFFFFC00\0" \
	"buildmac=setenv e "" ; setenv sep \"\"; for i in 0 1 2 3 4 5 ; do setexpr x 0xFFFFFC00 + $i ; setexpr.b b *$x ; setenv e \"$e$sep$b\" ; setenv sep : ; done && env set ethaddr $e && echo == MAC address set to $ethaddr from eeprom\0" \
	"bootargs=earlyprintk earlycon clk_ignore_unused cpuidle.off=1 uio_pdrv_genirq.of_id=generic-uio\0" \
	"devicetree_load_address=0x2000000\0" \
	"kernel_load_address=0x2080000\0" \
	"initrd_load_address=0x2A00000\0" \
	"bootnet=dhcp && tftpboot ${kernel_load_address} /mpmt/zynq/zImage && tftpboot ${devicetree_load_address} /mpmt/zynq/system.dtb && tftpboot ${initrd_load_address} /mpmt/zynq/rootfs.cpio.gz && bootz ${kernel_load_address} ${initrd_load_address} ${devicetree_load_address}\0" \
	"bootmmc=setenv bootargs ${bootargs} root=/dev/mmcblk0p1 rw rootwait cma=320M && load mmc 0 ${kernel_load_address} /boot/zImage && load mmc 0 ${devicetree_load_address} /boot/system.dtb && bootz ${kernel_load_address} - ${devicetree_load_address}\0" \
	"bootmedia=mmc\0" \
	"bootcmd=run boot${bootmedia}\0" \
	"flash_bootbin=tftpboot 0x09000000 mpmt/zynq/BOOT.BIN && sf probe 0 0 0 && sf erase 0 0x1000000 && sf write 0x09000000 0 ${filesize}\0"
