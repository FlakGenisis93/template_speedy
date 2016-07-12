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
#include "tpa81.h"


int main(int argc, char *argv[]){

	printf("===== I2C test =====\r\n");

	if(init_i2c(I2C_1) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}

	uint8_t version;
	version = read_version_srf08();
	printf("Version: %d\n", version);

	uint8_t temp;
	temp = read_umgebungs_temp();
	printf("Temperatur: %d\n", temp);

	uint8_t data[8];
	read_pixel_temp(0, data);


	return 0;
	
}
