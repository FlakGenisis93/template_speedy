/**
  *******************************************************************************************************************
  * @file      	max11613.c
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	18.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Functions to control max11613 modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 18.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
//	I	N	C	L	U	D	E	S

#include "max11613.h"

//	F	U	N	K	T	I	O	N	E	N

uint8_t write_setup_byte(void){

/*	bit 0	- Don't care
	bit 1 - RST_n
	bit 2 - BIP/UNI_n
	bit 3 - CLK
	Config SEL fuer external Ref
	bit 4 - SEL0		- x
	bit 5 - SEL1		- 1
	bit 6 - SEL2		- 0
	bit 7 - REG		- 1 = Setup Byte

	weiter Infos im Datenblatt*/

	uint8_t data = 0b10100010;

	//Schreiben auf I2C Bus
	if(write_i2c(I2C_2, ADDR_MAX11613, &data, 1) == 1)
		return 0;

	return -1;

}

uint8_t write_config_byte(void){

/*	bit 0	- SFL/DIF_n

	CS selektiert den Channel, hier wird bis 2 gescannt
	bit 1 - CS0		- 0
	bit 2 - CS1		- 1
	bit 3 - CS2		- 0
	bit 4 - CS3		- 0

	SCAN selektiert den SCAN mode, hier bis zum Channel wie in CS selektiert
	bit 5 - SCAN0	- 0
	bit 6 - SCAN1	- 0
	bit 7 - REG		- 0 = Config Byte

	weiter Infos im Datenblatt*/

	uint8_t data = 0b00000101;

	//Schreiben auf I2C Bus
	if(write_i2c(I2C_2, ADDR_MAX11613, &data, 1) == 1)
		return 0;

	return -1;

}

uint8_t read_data_max11613(uint8_t bytes, uint8_t data_max[]){

	uint8_t bytes_read;

	//Bytes muss eine gerade Zahl sein
	if( (bytes % 2) != 0  )
		return -2;

	//Lesen von I2C Bus
	bytes_read = read_i2c(I2C_2, ADDR_MAX11613, data_max, bytes);

	//byte die gelesen worden muessen den geforderten entsprechen
	if(bytes_read == bytes)
		return bytes_read;

	return -1;


}
