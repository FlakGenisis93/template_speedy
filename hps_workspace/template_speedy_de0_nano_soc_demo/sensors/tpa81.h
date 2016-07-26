/**
  *******************************************************************************************************************
  * @file      	tpa81.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	14.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control TPA81 modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 13.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
#ifndef TPA81_H_
#define TPA81_H_

//	I	N	C	L	U	D	E	S

#include "i2c.h"

//	D	E	F	I	N	E	S

#define ADDR_TPA81		0x68	/*! I2C HEX Addresse TPA81	*/ 

//	F	U	N	K	T	I	O	N	E	N

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_version_tpa81(void)
 *
 *	@details	Diese Funktion lies die Versionsnummer des TPA81
 *
 *	@param		void
 *
 *	@retval		x		Version
 *				-1		Fehler beim lesen oder schreiben auf I2C
 *
 *******************************************************************************************************************/

uint8_t read_version_tpa81(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_umgebungs_temp(void)
 *
 *	@details	Diese Funktion erstellt den XBee Frame 
 *
 *	@param		void
 *
 *	@retval		x		Umgebungstemperatur
 *				-1		Fehler beim lesen oder schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_umgebungs_temp(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		create_xbee_frame(uint16_t xbee_addr, uint8_t *xbee_frame, uint8_t daten[], uint16_t length)
 *
 *	@details	Diese Funktion erstellt den XBee Frame 
 *
 *	@param		uint8_t pixel		Welches Pixel ausgelsen werden soll
 *									1-8 lies jeweils das dazughörige Pixel ausgelsen
 *									0	liest alle 8 Pixel aus
 *	@param		uint8_t data_tpa[]	Arry für die daten, welches 1 oder 8 lang sein muss, abhänig vom Param: pixel
 *
 *	@retval		bytes read	gelesen bytes von I2C
 *				-1			Fehler beim lesen auf I2C
 *				-2			Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_pixel_temp(uint8_t pixel, uint8_t data_tpa[]);

#endif /* TPA81_H_ */
