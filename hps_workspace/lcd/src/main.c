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

#include "lcd.h"


int main(int argc, char *argv[]){

	printf("===== I2C test =====\r\n");

	if(init_i2c(I2C_2) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}

	uint8_t data_register[4];

	read_register_lcd(data_register);

	printf("Freie Bytes im FIFO: %d\n", data_register[0]);

	printf("Low byte: %d\n", data_register[1]);

	printf("High Byte: %d\n", data_register[2]);

	printf("Version: %d\n", data_register[3]);

	uint16_t keys;

	keys = read_key_lcd();

	printf("Keys: 0x%x\n", keys);

	clear_lcd();

	set_courser_lcd(2, 1);

	uint8_t text[] = {"Hallo Welt!"};

	write_data_lcd(text, sizeof(text));

	blacklight_on_lcd();



	printf("bye!\r\n");


	return 0;
	
}
