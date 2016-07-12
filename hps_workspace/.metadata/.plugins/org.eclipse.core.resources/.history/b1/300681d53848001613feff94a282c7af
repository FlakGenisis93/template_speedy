#include "itg3200.h"

uint8_t read_version_itg(void){

	uint8_t version = 0;

	uint8_t cmd_reg_0 = {0};

	write_i2c(I2C_1, ADDR_ITG, &cmd_reg_0, 1);

	read_i2c(I2C_1, ADDR_ITG, &version, 1);

	return version;
}
