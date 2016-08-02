/*
 * main.c
 *
 *  Created on: 06.07.2016
 *      Author: Urban
 */

#include "xbee.h"

int main(void){

	int memmory;
	void *virtual_base;
	volatile uint32_t *hps_xbee = NULL;
	uint8_t data[] = {0x48, 0x49}; 	//ASCI Zeichen in HEX fuer - Hi
	uint16_t addresse = 0x0401;		//HEX Adresse des anderen XBee-Moduls	

	if( ( memmory = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return 5;
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memmory, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close(memmory);
		return 6;
	}

	hps_xbee = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + FIFOED_AVALON_UART_BASE ) & (uint32_t)( HW_REGS_MASK ) );


	//Senden per XBee
	xbee_tx(hps_xbee, addresse, data, sizeof(data));

	//Empfangen per XBee
	//xbee_rx(hps_xbee);

	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( memmory );
		return 7;
	}

	close(memmory);

	return 0;


}
