/*
 * main.c
 *
 *  Created on: 06.07.2016
 *      Author: Urban
 */

#include "xbee.h"

int main(void){

	uint8_t data[] = {0x48, 0x49}; //Hi
	uint16_t addresse = 0x0401;


	xbee_tx(addresse, data, sizeof(data));

	//xbee_rx();

	return 0;


}
