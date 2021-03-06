/**
  *******************************************************************************************************************
  * @file      	gsensor_nano.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	18.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control gsensor on DE0 Nano SoC
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 18.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */

#ifndef GSENSOR_NANO_H_
#define GSENSOR_NANO_H_

//	I	N	C	L	U	D	E	S

#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "ADXL345.h"

//	F	U	N	K	T	I	O	N	E	N

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t hps_gsensor_messen(uint8_t messungen)
 *
 *	@details	Diese Funktion liest die die Daten des gsensors
 *
 *	@param		uint8_t messungen		Anzahl der Messungen
 *
 *	@retval		0	Alles ok
 *
 *******************************************************************************************************************/
 
uint8_t hps_gsensor_messen(uint8_t messungen);


#endif /* GSENSOR_NANO_H_ */
