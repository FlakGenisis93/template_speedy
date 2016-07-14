/**
  *******************************************************************************************************************
  * @file      	i2c.c
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	14.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Functions to control i2c modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 14.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
//	I	N	C	L	U	D	E	S

#include "i2c.h"

uint8_t init_i2c(uint32_t i2c_dev){

	void *virtual_base;
	volatile uint32_t *i2c_ic_con = NULL;
	volatile uint32_t *i2c_en = NULL;
	int fd;
	uint32_t daten_register;

	//Oeffnen der Datei des Speichers mit Fehlerabrage
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return 1;
	}

	//Erstellen einer Virtuellen Adresse
	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	//Fehlerabrage der Virtuellen Adresse
	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return 2;
	}

	//Erstellen einen Pointers auf das ic_con Register im Speicher
	i2c_ic_con = virtual_base + ( (uint32_t)( i2c_dev + ic_con ) & (uint32_t)( HW_REGS_MASK ) );
	//Erstellen einen Pointers auf das ic_enable Register im Speicher
	i2c_en = virtual_base + ( (uint32_t)( i2c_dev + ic_enable ) & (uint32_t)( HW_REGS_MASK ) );

	//Auschalten des I2C Moduls
	alt_clrbits_word(i2c_en, 0x1);
	//Auf 100kHz stellen
	alt_write_word(i2c_ic_con, ( (alt_read_word(i2c_ic_con) & 0xFFFFFFF9) | 0x00000002) );
	//Einschalten des I2C Moduls
	alt_setbits_word(i2c_en, 0x1);

	//Lesen des Registers
	daten_register = alt_read_word(i2c_ic_con);

	//Pruefen des Registerinhalts auf 0x73 oder 0x63
	if(daten_register != 0x73){
		if( daten_register != 0x63){
			close( fd );
			return 3;
		}
	}

	//Memorryunmapping aufheben mti Fehlerabfrage
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 4 );
	}

	//Datei schliesen
	close( fd );

	return 0;

}


uint32_t write_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length){

	int file;
	uint32_t bytes_written;
	const char *filename;

	//Abfrage welcher I2C Bus
	switch (i2c){

		//Setzen des Dateinamens
		case I2C_1:
			filename = "/dev/i2c-1";
		break;

		case I2C_2:
			filename = "/dev/i2c-2";
		break;

	}

	//Oeffnen der Datei des entsprechenden I2C Buses
	if ((file = open(filename, O_RDWR)) < 0) {
		perror("Konnte I2C nicht oeffnen\n");
		return -1;
	}
	
	//Festlegen der Adresse des Slaves
	if (ioctl(file, I2C_SLAVE, slave_adress) < 0) {
		printf("Konnte Bus nicht belegen\n");
		return -1;
	}

	//Schreiben in die Datei und speichern des Rueckgabewertes
	bytes_written = write(file, data, length);
	
	//Pruefen des Rueckgabewertes
	if ( bytes_written == length){
		
		//Datei schliesen
		close(file);
		//Rueckgabe der geschriebenen Bytes
		return bytes_written;
	}

	//Datei schliesen
	if (file)
		close(file);

	return -1;

}


uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length){

	int file;
	uint32_t bytes_read;
	const char *filename;

	//Abfrage welcher I2C Bus
	switch (i2c){

		//Setzen des Dateinamens
		case I2C_1:
			filename = "/dev/i2c-1";
		break;

		case I2C_2:
			filename = "/dev/i2c-2";
		break;

	}

	//Oeffnen der Datei des entsprechenden I2C Buses
	if ((file = open(filename, O_RDWR)) < 0) {
		perror("Konnte I2C nicht oeffnen\n");
		close(file);
		return -1;
	}

	//Festlegen der Adresse des Slaves
	if (ioctl(file, I2C_SLAVE, slave_adress) < 0) {
		printf("Konnte Bus nicht belegen\n");
		close(file);
		return -1;
	}

	//lesen in die Datei und speichern des Rueckgabewertes
	bytes_read = read(file, data, length);

	//Pruefen des Rueckgabewertes
	if (bytes_read == length){
		
		//Datei schliesen
		close(file);
		
		//Rueckgabe der gelesenen Bytes
		return bytes_read;
	}

	//Datei schliesen
	if (file)
		close(file);

	return -1;

}



