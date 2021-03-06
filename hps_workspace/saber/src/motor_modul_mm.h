/**
 ******************************************************************************
 * @file    motor_modul_mm.h
 * @author  BoE. Lt. Kluge Florian
 * @version V1.0.1
 * @date    17.08.2016
 * @brief   Befehle fuer motor_modul_mm - Header
 *
 ******************************************************************************
 *	@par History:
 * @details V0.0.1 Kluge F.
 *           - Erste Version, mit einzelnen senden der Befehle
 * @details V0.1.0 Kluge F.
 *           - drive-Befehl fertig
 * @details V0.2.0 Kluge F.
 *           - drive_turn-Befehl fertig
 * @details V0.2.1 Kluge F.
 *           - Befehle mit warte funktionen und doneflag optimiert
 * @details V0.3.0 Kluge F.
 *           - gyro funktionen implementiert
 * @details V0.4.0 Kluge F.
 *           - drive_turn jetzt mit offset
 * @details V0.5.0 Kluge F.
 *           - drive_curve implementiert
 * @details V1.0.0 Kluge F.
 *           - final version, drive_curve verbessert und doku
 * @details V1.0.1 Kluge F.
 *           - defines fuer IOWR/IORD-Funktionen angelegt
 ********************************************************************************
 * @brief
 * <h2><center>&copy; COPYRIGHT 2012 - 2016 UniBwM ETTI WE 4</center></h2>
 ********************************************************************************
 */

#ifndef MOTOR_MODUL__MM_H_
#define MOTOR_MODUL__MM_H_

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#include "hps_0.h"
#include "hwlib.h"
#include "time.h"
#include "i2c.h"
#include "itg3200.h"



//DRIVE-COMMAND/////////////////////////
#define DRIVE 		0x8001	//dez: 32769
#define DRIVE_TURN 	0x8002 	//dez: 32770
#define DRIVE_CURVE 0x8003	//deZ: 32771



//IOWR-Funktionen///////////////////////
#define SET_SPEED(base, speed)					alt_write_word(base + 0, speed)
#define SET_DISTANCE(base, distance)			alt_write_word(base + 1, distance)
#define SET_ANGLE(base, angle)					alt_write_word(base + 2, angle)
#define SET_RADIUS(base, radius)				alt_write_word(base + 3, radius)
#define SET_GYRO(base, gyro_result)				alt_write_word(base + 5, gyro_result)
#define SET_RESOLUTION(base, resolution)		alt_write_word(base + 6, resolution)
#define SET_CIRC_PART_M1(base, circle_part_m1)	alt_write_word(base + 7, circle_part_m1)
#define SET_CIRC_PART_M2(base, circle_part_m2)	alt_write_word(base + 8, circle_part_m2)

#define START_DRIVE(base)						alt_write_word(base + 4, DRIVE)
#define START_TURN(base)						alt_write_word(base + 4, DRIVE_TURN)
#define START_CURVE(base)						alt_write_word(base + 4, DRIVE_CURVE)


//IORD-Funktionen///////////////////////
#define GET_DONE_FLAG(base)						alt_read_word( base + 0)
#define GET_ENCODER1(base)						alt_read_word( base + 1)
#define GET_ENCODER2(base)						alt_read_word( base + 2)
#define GET_WINKEL_PART(base)					alt_read_word( base + 3)
#define GET_WINKEL_SUM(base)					alt_read_word( base + 4)

//Funktionen////////////////////////////
/**
  * @brief		int16_t getGyro_result()
  * @details	Funktion die einen Wert(hier: Z-Wert) vom Gyro holt.
  * @param		None
  * @retval		int16_t result, Wert vom Gyro
  */
int16_t getGyro_result();

/**
  * @brief		void drive(uint8_t speed, int16_t distance)
  * @details	Funktion die ueber das Interface den Fahrbefehl mit
  * 			entsprechenden Parametern aufruft. Terminiert nur bei
  * 			Erfolg.
  * @param		uint8_t speed:		Geschwindigkeit
  * 			int16_t distance:	Distanz die zurueckgelegt werden soll(+/-)
  * @retval		None
  */
void drive(volatile uint32_t *base_addr, uint8_t speed, int16_t distance);

/**
  * @brief		void drive_turn(uint8_t speed, int16_t angle)
  * @details	Funktion die ueber das Interface den Drehbefehl mit
  * 			entsprechenden Parametern aufruft. Terminiert nur bei
  * 			Erfolg.
  * @param		uint8_t speed:	Geschwindigkeit
  * 			int16_t angle:	Winkel der gedreht werden soll(+ ->rechts/- ->links)
  * @retval		None
  */
void drive_turn(volatile uint32_t *base_addr, uint8_t speed, int16_t angle);

/**
  * @brief		int16_t get_turn_offset()
  * @details	Funktion die 5 mal alle 100ms einen Wert vom Gyro holt
  * 			und diesen addiert und dann teilt um den offset zu bestimmen.
  * 			DARF nur aus dem Stillstand aufgerufen werden.
  * @param		None
  * @retval		int16_t gyro_offset, Wert des Offsets
  */
int16_t get_turn_offset();

/**
  * @brief		void drive_turn_w_offset(uint8_t speed, int16_t angle)
  * @details	Funktion die ueber das Interface den Drehbefehl mit
  * 			entsprechenden Parametern aufruft. Intern erfolgt die
  * 			bestimmung des Offsets, dauer dadurch 500ms laenger.
  * 			Terminiert nur bei Erfolg.
  * @param		uint8_t speed:	Geschwindigkeit
  * 			int16_t angle:	Winkel der gedreht werden soll(+ ->rechts/- ->links)
  * @retval		None
  */
void drive_turn_w_offset(volatile uint32_t *base_addr, uint8_t speed, int16_t angle);

/**
  * @brief		void drive_curve_steps(int16_t angle, uint8_t speed, int16_t radius, int16_t resolution)
  * @details	Funktion die ueber das Interface den Kurvenbefehl mit
  * 			entsprechenden Parametern aufruft. Intern erfolgt die
  * 			bestimmung des Offsets, dauer dadurch 500ms laenger.
  * 			Winkel ist momentan noch FIX vorgegeben(+-180grad), da die
  * 			Berechnungen noch nicht ohne Fehler funktionieren.
  * 			Terminiert nur bei Erfolg.
  * @param		int16_t angle:		Winkel
  * 			uint8_t speed:		Geschwindigkeit
  * 			int16_t radius:		Radius der Kurve
  * 			int16_t resolution:	Teilschritte auf dem Kreis der Kurve
  * @retval		None
  */
void drive_curve_steps(volatile uint32_t *base_addr, int16_t angle, uint8_t speed, int16_t radius, int16_t resolution);




#endif /* MOTOR_MODUL_MM_H_ */
