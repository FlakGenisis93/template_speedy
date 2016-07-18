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

#ifndef SRF08_H_
#define SRF08_H_

//	I	N	C	L	U	D	E	S

#include <stdint.h>

#include "i2c.h"

//	D	E	F	I	N	E	S

#define SRF_HL	0x71	/*! Adresse des SRF Moduls hinten links */
#define SRF_V	0x72	/*! Adresse des SRF Moduls vorne */
#define SRF_HR	0x73	/*! Adresse des SRF Moduls hinten rechts */

//	F	U	N	K	T	I	O	N	E	N

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_version_srf08(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion liest die Version des SRF Moduls aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		x	Version
 *				-1	Fehler beim lesen oder schreiben auf I2C
 *
 *******************************************************************************************************************/

uint8_t read_version_srf08(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_distance_srfx_zoll(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion startet eine Messung in Zoll
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_distance_srfx_zoll(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_distance_srfx_cm(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion startet eine Messung in cm
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_distance_srfx_cm(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_distance_srfx_us(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion startet eine Messung in us
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_distance_srfx_us(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_aan_zoll(void)
 *
 *	@details	Diese Funktion startet eine AAN Messung in Zoll
 *
 *	@param		void	Alle SRF Module werden angesprochen
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_aan_zoll(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_aan_cm(void)
 *
 *	@details	Diese Funktion startet eine AAN Messung in cm
 *
 *	@param		void	Alle SRF Module werden angesprochen
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_aan_cm(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t measure_aan_us(void)
 *
 *	@details	Diese Funktion startet eine AAN Messung in us
 *
 *	@param		void	Alle SRF Module werden angesprochen
 *
 *	@retval		0	Alles Ok
 *				1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t measure_aan_us(void);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_lumen_srfx(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion liest die Helligkeit in Lumen aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		x	Lumen
 *				-1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_lumen_srfx(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint16_t read_data_srfx(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion liest die kuerzeste Entfernung aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		x	Entferung 
 *				-1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint16_t read_data_srfx(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_all_data_srfx(uint8_t adresse_srf, uint16_t werte_srf[17])
 *
 *	@details	Diese Funktion liest alle gemessenen Entfernungen aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 * 				uint16_t werte_srf[17]	Array fuer die Daten, dieses muss 17 Felder lang sein
 *
 *	@retval		x	Anzahl der Werte 
 *				-1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_all_data_srfx(uint8_t adresse_srf, uint16_t werte_srf[17]);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint16_t read_data_einheit_aan_srfx(uint8_t adresse_srf)
 *
 *	@details	Diese Funktion liest die kuerzeste Entferung in der Einheit aus wie die AAN Messung gestartet wurde aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *
 *	@retval		x	Entferung 
 *				-1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint16_t read_data_einheit_aan_srfx(uint8_t adresse_srf);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_data_aan_srfx(uint8_t adresse_srf, uint16_t werte_aan[14])
 *
 *	@details	Diese Funktion liest die AAN Werte aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 * 				uint16_t werte_aan[14]	Array fuer die Daten, dieses muss 14 Felder lang sein
 *
 *	@retval		0	Alles Ok				
 *				-1	Fehler beim schreiben auf I2C
 *
 *******************************************************************************************************************/
 
uint8_t read_data_aan_srfx(uint8_t adresse_srf, uint16_t werte_aan[14]);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t read_all_data_aan_srfx(uint8_t adresse_srf, uint16_t *wert_einheit, uint16_t werte_aan[14]
 *
 *	@details	Diese Funktion liest die AAN Werte, sowie den Wert mit der gewuenschten Einheit aus
 *
 *	@param		uint8_t adresse_srf		Adresse des SRF Moduls
 *				uint16_t *wert_einheit	Entfernung in Einheit
 * 				uint16_t werte_aan[14]	Array fuer die Daten, dieses muss 14 Felder lang sein
 *
 *	@retval		0	Alles Ok	
 *				-1	Fehler beim schreiben auf I2C bei read_data_einheit_aan_srfx 
 *				-2	Fehler beim schreiben auf I2C bei read_data_aan_srfx
 *
 *******************************************************************************************************************/
 
uint8_t read_all_data_aan_srfx(uint8_t adresse_srf, uint16_t *wert_einheit, uint16_t werte_aan[14]);

#endif /* SRF08_H_ */
