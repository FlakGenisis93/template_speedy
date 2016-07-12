/*
 * main.c
 *
 *  Created on: 30.06.2016
 *      Author: Urban
 */

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#include "hps_0.h"
#include "hwlib.h"
#include "motor_modul.h"

#define HW_REGS_BASE 	( ALT_STM_OFST )
#define HW_REGS_SPAN 	( 0x04000000 )
#define HW_REGS_MASK 	( HW_REGS_SPAN - 1 )


int main() {

	void *virtual_base;
	volatile uint32_t *hps_saber = NULL;
	int fd;
	//uint32_t daten, i;
	//char daten_reg[2048];


	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	hps_saber = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + MOTOR_MODUL_BASE ) & (uint32_t)( HW_REGS_MASK ) );

	/*//Init Lasermodul
	daten = init_laser(hps_laser);
	if ( daten != 0) {
		printf("Fehler bei Initzialisierung\n");
	} else {
		printf("Init OK\n");
	}

	//Schreiben ins Befehlsregister
	alt_write_word(hps_laser, 2);

	//Pruefen des Befehlsregisters
	daten = alt_read_word( hps_laser + REG_R_BEFEHL);
	printf("Befehlsregister = %i\n", daten);

	//Loeschen des Befhelsregisters
	alt_write_word(hps_laser, 0);

	//Speicher lesen
	for(i = 0; i < 2048; i++){

		//Zelle waehlen
		alt_write_word(hps_laser + REG_W_ZELLE , i);
		//Zelle lesen
		daten_reg[i] = alt_read_word( hps_laser );

		}*/

	uint16_t distance[2048];
	doMeasurement(hps_laser, &distance);


	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return( 0 );
}
