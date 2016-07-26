/**
  *******************************************************************************************************************
  * @file      	tpa81.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	13.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control TPA81 modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 13.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
//	I	N	C	L	U	D	E	S

#include "tpa81.h"

//	F	U	N	K	T	I	O	N	E	N

uint8_t read_version_tpa81(void){

	uint8_t version = 0;

	//Festlegen des zu lesenden Registers
	uint8_t cmd_reg_0 = {0};
	
	//Registernr an modul schreiben
	if(write_i2c(I2C_1, ADDR_TPA81, &cmd_reg_0, 1) != 1)
		return -1;

	//Lesen der Versionsnummer
	if(read_i2c(I2C_1, ADDR_TPA81, &version, 1) != 1)
		return -1;

	//Rueckgabe der Verison
	return version;
}

uint8_t read_umgebungs_temp(void){

	uint8_t temperatur = 0;

	//Festlegen des zu lesenden Registers
	uint8_t cmd_reg_1 = {1};

	//Registernr an modul schreiben
	if(write_i2c(I2C_1, ADDR_TPA81, &cmd_reg_1, 1) != 1)
		return -1;

	//Lesen der Umgebungstemperatur
	if(read_i2c(I2C_1, ADDR_TPA81, &temperatur, 1) != 1)
		return -1;
	
	//Rueckgabe der Umgebungstemperatur
	return temperatur;
}

uint8_t read_pixel_temp(uint8_t pixel, uint8_t data_tpa[]){

	uint8_t byte = 1;
	uint8_t command;
	uint8_t bytes_read;

	//Festlegen des Rigsters ab dem gelesen werden soll, abhaenig vom Patam: pixel
	switch (pixel){

			//Alle pixel
			case 0:
				byte = 8;
				command = 2;
				break;
			case 1:
				command = 2;
				break;
			case 2:
				command = 3;
				break;
			case 3:
				command = 4;
				break;
			case 4:
				command = 5;
				break;
			case 5:
				command = 6;
				break;
			case 6:
				command = 7;
				break;
			case 7:
				command = 8;
				break;
			case 8:
				command = 9;
				break;
		}

	//Registernr an modul schreiben
	if(write_i2c(I2C_1, ADDR_TPA81, &command, 1) != 1)
		return -2;


	//Lesen der Daten vom Modul
	bytes_read = read_i2c(I2C_1, ADDR_TPA81, data_tpa, byte);

	//Pruefen ob die geforderten Bytes gelesen wurden
	if(bytes_read == byte)
		return bytes_read;

	return -1;

}
