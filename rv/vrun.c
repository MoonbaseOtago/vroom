#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <assert.h>

#include <stdbool.h>
#include <stdarg.h>
#include <string.h>

#include <fcntl.h>


#ifdef SV_TEST
   #include "fpga_pci_sv.h"
#else
   #include <fpga_pci.h>
   #include <fpga_mgmt.h>
   #include <utils/lcd.h>
#endif


#include <utils/sh_dpi_tasks.h>
#include <sys/mman.h>


const struct logger *logger = &logger_stdout;
//static uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
//static uint16_t pci_device_id = 0xF000; /* PCI Device ID preassigned by Amazon for F1 applications */


int
main(int argc, const char **argv)
{
	int rc;
	struct fpga_mgmt_image_info info = {0};

	int slot_id = 0;
	unsigned char *fbase;
	int map=-1;
	off_t file_size;
	int i;
	

	if (argc < 1) {
		fbase = 0;
		file_size = 0;
	} else {
		struct stat s;
		map = open(argv[1], O_RDWR);
		assert(map >=0);
		assert(fstat(map, &s)==0);
		file_size = s.st_size;
		fbase = (unsigned char *)mmap(NULL, file_size, PROT_READ | PROT_WRITE, MAP_SHARED, map, 0);
		assert(((uint64_t)fbase) != -1u);
	}
	
	rc = fpga_mgmt_init();
	assert (rc == 0);

	rc = fpga_mgmt_describe_local_image(slot_id, &info, 0);
	assert (rc ==0);

	switch (info.status) {
	case 0: printf("state: loaded\n"); break;
	case 1: printf("state: cleared\n"); break;
	case 2: printf("state: busy\n"); break;
	case 3: printf("state: not-programmed\n"); break;
	case 7: printf("state: loaded\n"); break;
	default: printf("state: internal error\n"); break;
	}

	printf("Vendor ID: 0x%x\n", info.spec.map[FPGA_APP_PF].vendor_id);
	printf("Device ID: 0x%x\n", info.spec.map[FPGA_APP_PF].device_id);
	
	pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;


	rc = fpga_pci_attach(slot_id, FPGA_APP_PF, APP_PF_BAR4, 0, &pci_bar_handle);
	assert(rc==0);

	void *vbase;
	rc = fpga_pci_get_address(pci_bar_handle, 0, 4*1024, &vbase);
	assert(rc==0);
	volatile uint64_t *b = (uint64_t*)vbase;
	assert(b);

#define REG_RESET	(8*512/64) 
#define REG_GPIO	(9*512/64) 
#define REG_UART_STATE	(0*512/64) 
#define REG_UART_READ	(3*512/64) 
#define REG_UART_SPEED	(4*512/64) 

#define REG_SD_FIFO 	(0x10*512/64)
#define REG_SD_STATE 	(0x11*512/64)
#define REG_SD_MAGIC 	(0x12*512/64)
	printf("sanity = 0x%lx\n", b[REG_SD_MAGIC]);
	printf("uart =  0x%lx\n", b[REG_UART_SPEED]);

	b[REG_UART_SPEED] = 0x2f;
	b[REG_RESET] = 0;	// out of reset

	for (;;) {
		uint64_t uart = b[REG_UART_STATE];
printf("uart = 0x%lx\n",uart);
		if (!(uart&(1<<6))) { 
			putchar((char)(b[REG_UART_READ]&0xff));
			continue;
		}
		uint64_t sd = b[REG_SD_STATE];
printf("sd = 0x%lx\n",sd);
		if (sd&1) {
			uint64_t addr = sd&0xffffffff0U;
printf("addr = 0x%lx\n",addr);
			if (sd&2) { 	// read
				if (addr == 0xfffffff00U) {
					addr = 0;	// map from beginning
				} else {
					addr += 256;	// skip map
				}
				if (!fbase || (addr+256) > file_size) {
					for (i = 0; i < (256/8); i++)
						b[REG_SD_FIFO] = 0;
				} else {
					uint64_t *f = (uint64_t *)(fbase+addr);
					for (i = 0; i < (256/8); i++)
						b[REG_SD_FIFO] = *f++;
				}
			} else {	// write
				uint64_t *f = (uint64_t *)(fbase+addr);
				volatile uint64_t x;
				if (!fbase || (addr+256) > file_size) {
					for (i = 0; i < (256/8); i++)
						x = b[REG_SD_FIFO];
				} else {
					for (i = 0; i < (256/8); i++)
						*f++ = b[REG_SD_FIFO];
				}
			}
			continue;
		}
	}
	return 0;
}
