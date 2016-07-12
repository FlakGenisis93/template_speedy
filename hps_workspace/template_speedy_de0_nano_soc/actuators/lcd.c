#include "lcd.h"

uint32_t read_register_lcd(uint8_t data[4]){

	uint8_t reg_addr[] = {0};

	write_i2c(I2C_2, LCD03_ADRESS, reg_addr, 1);

	if(read_i2c(I2C_2, LCD03_ADRESS, data, 4) == 4){
		return 0;
	}

	return -1;

}

uint16_t read_key_lcd(void){

	uint8_t register_daten[2];
	uint8_t reg_addr[] = {1};
	uint16_t data = 0;

	write_i2c(I2C_2, LCD03_ADRESS, reg_addr, 1);

	if(read_i2c(I2C_2, LCD03_ADRESS, register_daten, 2) == 2){

		data = register_daten[0] | ( register_daten[1] << 8);

		return data;
	}

	return -1;

}

uint8_t read_free_fifo_lcd(void){

	uint8_t register_daten[1];
	uint8_t reg_addr[] = {0};

	write_i2c(I2C_2, LCD03_ADRESS, reg_addr, 1);

	if(read_i2c(I2C_2, LCD03_ADRESS, register_daten, 1) == 1){

		return register_daten[0];
	}

	return -1;

}

uint8_t write_data_lcd(uint8_t data[], uint8_t length){

	uint8_t i;
	uint8_t data_reg[length + 1];
	data_reg[0] = 0;

	for(i = 0; i < length; i++){
		data_reg[i + 1] = data[i];
	}


	if(write_i2c(I2C_2, LCD03_ADRESS, data_reg, length + 1) == length + 1){
		return 0;
	}

	return -1;

}


uint8_t clear_lcd(void){

	uint8_t clear_display[] = {12};

	if(write_data_lcd(clear_display, 1) == 0){
		return 0;
	}

	return -1;

}

uint8_t set_courser_lcd(uint8_t line, uint8_t column){

	uint8_t data[3];
	data[1] = 3;
	data[1] = line;
	data[2] = column;

	if(write_data_lcd(data, 3) == 0){
		return 0;
	}

	return -1;

}

uint8_t blacklight_on_lcd(void){

	uint8_t blacklight_on[] = {19};

	if(write_data_lcd(blacklight_on, 1) == 0){
		return 0;
	}

	return -1;

}

uint8_t blacklight_off_lcd(void){

	uint8_t blacklight_off[] = {20};

	if(write_data_lcd(blacklight_off, 1) == 0){
		return 0;
	}

	return -1;

}
