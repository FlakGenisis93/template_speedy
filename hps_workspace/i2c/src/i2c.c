#include "i2c.h"


int init_i2c(uint32_t i2c_dev){

	void *virtual_base;
	volatile uint32_t *i2c_ic_con = NULL;
	volatile uint32_t *i2c_en = NULL;
	int fd;
	uint32_t daten_register;


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

	i2c_ic_con = virtual_base + ( (uint32_t)( i2c_dev + ic_con ) & (uint32_t)( HW_REGS_MASK ) );
	i2c_en = virtual_base + ( (uint32_t)( i2c_dev + ic_enable ) & (uint32_t)( HW_REGS_MASK ) );

	printf("Daten Register: 0x%x\n", alt_read_word(i2c_ic_con));

	alt_clrbits_word(i2c_en, 0x1);
	alt_write_word(i2c_ic_con, ( (alt_read_word(i2c_ic_con) & 0xFFFFFFF9) | 0x00000002) );
	alt_setbits_word(i2c_en, 0x1);

	daten_register = alt_read_word(i2c_ic_con);

	printf("Daten Register: 0x%x\n", daten_register);

	if(daten_register != 0x73){
		if( daten_register != 0x63){
			close( fd );
			return( 1 );
		}
	}

	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return 0;

}


uint32_t write_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length){

	int file;
	uint32_t bytes_written;
	const char *filename;

	switch (i2c){

		case I2C_1:
			filename = "/dev/i2c-1";
		break;

		case I2C_2:
			filename = "/dev/i2c-2";
		break;

	}

	if ((file = open(filename, O_RDWR)) < 0) {
		perror("Konnte I2C nicht oeffnen\n");
		return -1;
	}

	if (ioctl(file, I2C_SLAVE, slave_adress) < 0) {
		printf("Konnte Bus nicht belegen\n");
		return -1;
	}

	bytes_written = write(file, data, length);
	if ( bytes_written == length){
		close(file);
		return bytes_written;
	}

	if (file)
		close(file);

	return -1;

}


uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length){

	int file;
	uint32_t bytes_read;
	const char *filename;

	switch (i2c){

		case I2C_1:
			filename = "/dev/i2c-1";
		break;

		case I2C_2:
			filename = "/dev/i2c-2";
		break;

	}

	if ((file = open(filename, O_RDWR)) < 0) {
		perror("Konnte I2C nicht oeffnen\n");
		close(file);
		return -1;
	}

	if (ioctl(file, I2C_SLAVE, slave_adress) < 0) {
		printf("Konnte Bus nicht belegen\n");
		close(file);
		return -1;
	}

	bytes_read = read(file, data, sizeof(data));

	if (bytes_read == sizeof(data)){
		close(file);
		return bytes_read;
	}

	if (file)
		close(file);

	return -1;

}



