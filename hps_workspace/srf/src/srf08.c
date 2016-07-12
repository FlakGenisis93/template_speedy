#include "srf08.h"

uint8_t read_version_srf08(uint8_t adresse_srf){

	uint8_t version = 0;

	uint8_t cmd_reg_0 = {0};

	write_i2c(I2C_1, adresse_srf, &cmd_reg_0, 1);

	read_i2c(I2C_1, adresse_srf, &version, 1);

	return version;
}

uint8_t measure_distance_srfx_zoll(uint8_t adresse_srf){

	uint8_t command[] = {0x0, 0x50};

	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_distance_srfx_cm(uint8_t adresse_srf){

	uint8_t command[] = {0x0, 0x51};

	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_distance_srfx_us(uint8_t adresse_srf){

	uint8_t command[] = {0x0, 0x52};

	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}


uint8_t measure_aan_zoll(void){

	uint8_t command[] = {0x0, 0x53};

	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_aan_cm(void){

	uint8_t command[] = {0x0, 0x54};

	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_aan_us(void){

	uint8_t command[] = {0x0, 0x55};

	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t read_lumen_srfx(uint8_t adresse_srf){

	uint8_t lumen = 0;
	uint8_t reg_lumen = 1;

	write_i2c(I2C_1, adresse_srf, &reg_lumen, 1);

	read_i2c(I2C_1, 0x71, &lumen, 1);

	return lumen;
}

uint16_t read_data_srfx(uint8_t adresse_srf){

	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[] = {0, 0};
	uint16_t wert_srf;

	write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1);

	if( read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
				return -1;

	wert_srf = entfernung[1];

	wert_srf = wert_srf | (entfernung[0] << 8);

	return wert_srf;

}

uint8_t read_all_data_srfx(uint8_t adresse_srf, uint16_t werte_srf[]){

	uint8_t i = 0;
	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[2];


	write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1);

	do {

		entfernung[0] = 0;
		entfernung[1] = 0;

		if(read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
			return -1;

		werte_srf[i] = entfernung[1];

		werte_srf[i] = werte_srf[i] | (entfernung[0] << 8);

		if((entfernung[1] != 0) || (entfernung[0] != 0))
			i++;

	} while ( (entfernung[1] != 0) || (entfernung[0] != 0) );


	return i;
}

uint16_t read_data_einheit_aan_srfx(uint8_t adresse_srf){

	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[] = {0, 0};
	uint16_t wert_srf;

	write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1);

	if( read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
				return -1;

	wert_srf = entfernung[1];

	wert_srf = wert_srf | (entfernung[0] << 8);

	return wert_srf;

}

uint8_t read_data_aan_srfx(uint8_t adresse_srf, uint16_t werte_aan[]){

	uint8_t i;
	uint8_t reg_aan_data = 4;
	uint8_t entfernung[28];

	write_i2c(I2C_1, adresse_srf, &reg_aan_data, 1);

	if(read_i2c(I2C_1, adresse_srf, entfernung, 28) != 2)
		return -1;

	for( i = 0; i < 14; i++){
		werte_aan[i] = entfernung[1 + i*2];

		werte_aan[i] = werte_aan[i] | (entfernung[0 + i*2] << 8);

	}

	return 0;
}

uint8_t read_all_data_aan_srfx(uint8_t adresse_srf, uint16_t *wert_einheit, uint16_t werte_aan[]){

	*wert_einheit = read_data_einheit_aan_srfx(adresse_srf);

	if(read_data_aan_srfx(adresse_srf, werte_aan) == -1)
		return -1;

	return 0;
}


