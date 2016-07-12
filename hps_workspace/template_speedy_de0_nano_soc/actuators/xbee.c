#include "xbee.h"

__inline__ uint8_t XBEE_FRAME_CHECKSUM(uint8_t* frameData, uint8_t lenghtOfDataInBytes)
{
	if(frameData == NULL || lenghtOfDataInBytes < 1)
	{
		return 0xff;
	} else {
		uint16_t sum = 0x0000;
		uint8_t i = 0;
		for(i = 0; i < lenghtOfDataInBytes; i++)
		{
			sum = sum + frameData[i];
		}
		return (0xff - (sum & 0xff));
	}
}

uint8_t create_xbee_frame(uint16_t xbee_addr, uint8_t *xbee_frame, uint8_t daten[], uint16_t length){

	uint32_t i;
	uint16_t data_length;
	uint8_t msb_length;
	uint8_t lsb_length;
	uint8_t msb_addr;
	uint8_t lsb_addr;

	data_length = length + 5;

	lsb_length = data_length;
	msb_length = (data_length >> 8);

	lsb_addr = xbee_addr;
	msb_addr = (xbee_addr >> 8);

	xbee_frame[0] = 0x7E;
	xbee_frame[1] = msb_length;
	xbee_frame[2] = lsb_length;
	xbee_frame[3] = 0x01;	//Transmitrequest 16bit
	xbee_frame[4] = 0x01;
	xbee_frame[5] = msb_addr;
	xbee_frame[6] = lsb_addr;
	xbee_frame[7] = 0x00;

	for(i = 0; i < length; i++){
		xbee_frame[i + 8] = daten[i];
	}



	xbee_frame[length + 8] = XBEE_FRAME_CHECKSUM(&xbee_frame[3], data_length);

	if(xbee_frame[length + 8] == 0xFF)
		return -1;

	return 0;
}

uint8_t xbee_tx(uint16_t xbee_addr, uint8_t daten[], uint16_t length){

	void *virtual_base;
	volatile uint32_t *hps_xbee = NULL;
	int fd;
	uint8_t xbee_frame[length + 9];
	uint32_t i;

	if(create_xbee_frame(xbee_addr, xbee_frame, daten, length) == -1)
		return -1;

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return -1;
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return -1;
	}

	hps_xbee = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + FIFOED_AVALON_UART_BASE ) & (uint32_t)( HW_REGS_MASK ) );

	for(i = 0; i < length + 9; i++){

		//Schreiben an UART
		alt_write_word(hps_xbee + 0x1, xbee_frame[i]);

	}

	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close(fd);
		return -1;
	}

	close(fd);

	return 0;
}

uint8_t xbee_rx(){

	void *virtual_base;
	volatile uint32_t *hps_xbee = NULL;
	int fd;
	uint16_t fifo_used;
	uint32_t i;


	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close(fd);
		return -1;
	}

	hps_xbee = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + FIFOED_AVALON_UART_BASE ) & (uint32_t)( HW_REGS_MASK ) );

	alt_write_word(hps_xbee + 0x3, 0x2000);

	while(1){

		if( (alt_read_word(hps_xbee + 0x2) & 0x2000) >>13 ){

			fifo_used = alt_read_word(hps_xbee + 0x6);

			uint8_t daten[fifo_used];

			for(i = 0; i < fifo_used; i++){

				daten[i] = alt_read_word(hps_xbee);
				printf("%.2x", daten[i]);

			}

			alt_write_word(hps_xbee + 0x2, 0x2000);

		}


	}


	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return -1;
	}

	close(fd);

	return 0;
}
