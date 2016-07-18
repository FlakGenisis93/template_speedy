/**
  *******************************************************************************************************************
  * @file      	srf08.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	14.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control srf08 modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 14.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
#ifndef MAX11613_H_
#define MAX11613_H_

//	I	N	C	L	U	D	E	S

#include <stdint.h>
#include "i2c.h"

//	D	E	F	I	N	E	S

#define ADDR_MAX11613	0x34

//	F	U	N	K	T	I	O	N	E	N

uint8_t write_setup_byte(void);
uint8_t write_config_byte(void);
uint8_t read_data_max11613(uint8_t bytes, uint8_t data_max[]);

#endif /* MAX11613_H_ */
