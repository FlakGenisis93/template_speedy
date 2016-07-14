/**
  *******************************************************************************************************************
  * @file      	i2c.h
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	13.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Header functions to control i2c modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 13.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
 #ifndef I2C_H_
#define I2C_H_

//	I	N	C	L	U	D	E	S

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

//	D	E	F	I	N	E	S

#define HW_REGS_BASE	ALT_STM_OFST		/*! Offset fuer Register Base im Speicher */
#define HW_REGS_SPAN 	0x04000000			/*! Registerspanne im Speicher */
#define HW_REGS_MASK 	HW_REGS_SPAN - 1	/*! Maske fuer Registerspanne im Speicher */

#define I2C_1		0xFFC05000		/*! Speicheradresse I2C 1	*/
#define I2C_2		0xFFC06000		/*! Speicheradresse I2C 2	*/
#define ic_con		0x00000000		/*! Offset ic_con-Register	*/
#define ic_enable	0x0000006C		/*! Offset ic_enable-Register	*/

//	F	U	N	K	T	I	O	N	E	N

/**
 *******************************************************************************************************************
 *
 *	@brief		uint8_t init_i2c(uint32_t i2c_dev)
 *
 *	@details	Diese Funktion initialisiert I2C 
 *
 *	@param		uint32_t i2c_dev	32bit Speicheradresse des I2C Buses
 *
 *	@retval		0	Alles Okay
 *				1	Fehler beim oeffnen der Datei /dev/mem
 *				2	mmap() failed
 *				3	Schreiben in das Register schlug fehl
 *				4	munmap() failed
 *
 *******************************************************************************************************************/

uint8_t init_i2c(uint32_t i2c_dev);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length)
 *
 *	@details	Diese Funktion liest vom I2C Bus
 *
 *	@param		uint32_t i2c			32bit Speicheradresse des I2C Buses
 *				uint8_t slave_adress	8bit Slaveadresse
 *				uint8_t data[]			Daten die gelesen werden sollen
 *				uint8_t length			Laenge der Daten die gelesen werden sollen
 *
 *	@retval		x	bytes gelesen
 *				-1	Fehler
 *
 *******************************************************************************************************************/
 
uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length);

/**
 *******************************************************************************************************************
 *
 *	@brief		uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length)
 *
 *	@details	Diese Funktion liest vom I2C Bus
 *
 *	@param		uint32_t i2c			32bit Speicheradresse des I2C Buses
 *				uint8_t slave_adress	8bit Slaveadresse
 *				uint8_t data[]			Daten die geschrieben werden sollen
 *				uint8_t length			Laenge der Daten die geschrieben werden sollen
 *
 *	@retval		x	bytes geschrieben
 *				-1	Fehler
 *
 *******************************************************************************************************************/
 
uint32_t write_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length);

#endif /* I2C_H_ */
