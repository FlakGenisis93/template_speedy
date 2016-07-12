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
#include "srf08.h"


int main(int argc, char *argv[]){

	printf("===== I2C test =====\r\n");

	if(init_i2c(I2C_1) != 0){
		printf("Init I2C 100kHz Failed\n");
		return -1;
	} else {
		printf("Init I2C 100kHz successful\n");
	}

	uint8_t version;

	version = read_version_srf08(SRF_HL);

	printf("Version 0x%x: %d\n", SRF_HL, version);

	version = read_version_srf08(SRF_V);

	printf("Version 0x%x: %d\n", SRF_V, version);

	measure_distance_srfx_cm(SRF_HL);
	measure_distance_srfx_cm(SRF_V);

	usleep(70*1000);

	uint8_t lumen[2];

	lumen[0] = read_lumen_srfx(SRF_HL);
	lumen[1] = read_lumen_srfx(SRF_V);

	printf("Lumen 0x%x: %d\n", SRF_HL, lumen[0]);
	printf("Lumen 0x%x: %d\n", SRF_V, lumen[1]);

	uint8_t werte, j;
	uint16_t messwerte[17];
	werte = read_all_data_srfx(SRF_HL, messwerte);

	for(j = 0; j < werte; j++){
		printf("SRF 0x%x Entfernung in cm: %d\n", SRF_HL, messwerte[j]);
	}

	werte = read_all_data_srfx(SRF_V, messwerte);

	for(j = 0; j < werte; j++){
		printf("SRF 0x%x Entfernung in cm: %d\n", SRF_V, messwerte[j]);
	}


	uint16_t entfernung[] = {0, 0};
	measure_aan_cm();

	usleep(100*1000);

	entfernung[0] = read_data_einheit_aan_srfx(SRF_HL);
	entfernung[1] = read_data_einheit_aan_srfx(SRF_V);

	printf("AAN 0x%x: %d\n", SRF_HL, entfernung[0]);
	printf("AAN 0x%x: %d\n", SRF_V, entfernung[1]);








	return 0;
	
}
