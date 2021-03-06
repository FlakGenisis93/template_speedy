#include <stdio.h>


#include "i2c.h"
#include "itg3200.h"


int main(int argc, char *argv[]){

	if(init_i2c(I2C_2) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}

	init_itg();

	uint8_t version;
	version = read_version_itg();

	printf("Version: %d\n", version);

	uint16_t temp;
	temp = read_temp_itg();

	printf("Temperatur: %d\n", temp);

	int16_t grad;

	while(1){

		grad = read_gyro_z();

		if (grad < 0){
			grad = grad *-1;
		}

		grad = ((grad*1000)/14375);

		printf("Grad/sec %d\n", grad);
		usleep(100*1000);
	}

	return 0;
	
}
