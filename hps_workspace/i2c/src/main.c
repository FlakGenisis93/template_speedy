#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#include "i2c.h"


int main(int argc, char *argv[]){
	
	uint8_t write_data[2];
	uint8_t read_data[4];
	uint32_t byte;

	printf("===== I2C test =====\r\n");

	if(init_i2c(I2C_2) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}


	byte =  read_i2c(I2C_2, 0x63, read_data, 4);
	printf("Bytes read: %d\n", byte);

	printf("Freie Bytes im FIFO: %d\n", read_data[0]);

	printf("Low byte: %d\n", read_data[1]);

	printf("High Byte: %d\n", read_data[2]);

	printf("Version: %d\n", read_data[3]);


	write_data[0] = 0;
	write_data[1] = 1;

	byte = write_i2c(I2C_2, 0x63, write_data, 2);
	printf("Bytes written: %d\n", byte);

    
	printf("bye!\n");


	return 0;
	
}
