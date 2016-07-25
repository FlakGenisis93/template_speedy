/**
  *******************************************************************************************************************
  * @file      	xbee.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	13.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control Xbee modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 13.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */

#ifndef HMC6343_H_
#define HMC6343_H_

//	I	N	C	L	U	D	E	S

#include <stdint.h>

#include "i2c.h"

//	D	E	F	I	N	E	S

#define ADDR_HMC	0x19

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t write_cmd_hmc(uint8_t command)
 *
 *	@details	Diese Funktion schreibt einen Befehl an das HMC6343
 *
 *	@param		uint8_t command		Befehl gem. Datenblatt
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t write_cmd_hmc(uint8_t command);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t post_heading_data(void)
 *
 *	@details	Heading Data verarbeiten
 *
 *	@param		void
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t post_heading_data(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_data_hmc(uint8_t data_hmc[])
 *
 *	@details	Diese Funktion liest die Daten des HMC aus
 *
 *	@param		uint8_t data_hmc[]	Pointer fuer Datenmin 6 Felder groß
 *
 *	@retval		x	Bytes read
 *				1	Fehler beim lesen auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_data_hmc(uint8_t data_hmc[]);

#endif /* HMC6343_H_ */
