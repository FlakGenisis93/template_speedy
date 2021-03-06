#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>

#include "i2c.h"
#include "hmc6343.h"


int main(int argc, char *argv[]){

	if(init_i2c(I2C_2) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}

	post_heading_data();

	usleep(2*1000);

	uint8_t daten[6];

	read_data_hmc(daten);

	uint16_t serial;

	serial = read_serial_hmc();

	printf("Serialnr.: %d", serial);

	return 0;
	
}
