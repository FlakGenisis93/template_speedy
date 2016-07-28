#include "speedy.h"

int main(void) {

	uint8_t init;			//Variable fuer init_speedy
	uint16_t key;

	uint8_t text_1[] = {"     HPS Speedy     "
				  	  	"\n"
				  	  	" INIT: Ok  Press #  "
						"\n"};

	uint8_t text_2[] = {"\n"
						" * + # = Terminate  "
						"\n"
						"      Press #       "};

	//Anpassen wie benoetigt
	uint8_t text_3[] = {"1 Fahre gerade      "
						"2 Drehen rechts     "
						"3 180 Grad Kurve    "
						"4 Sende Laser       "};

	int memmory;			//file pointer fuer speicher
	void *virtual_base;
	volatile uint32_t *hps_laser = NULL;
	volatile uint32_t *hps_saber = NULL;
	volatile uint32_t *hps_xbee = NULL;



	//Init Speedy Peripheral, no Laser and Drive
	init = init_speedy();

	if(init != 0){
		printf("Init Speedy Failed: %d", init);
		return init;
	}

	//Init HPS Bridge

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

	hps_laser = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + LASER_BASE ) & (uint32_t)( HW_REGS_MASK ) );
	hps_saber = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + MOTOR_MODUL_BASE ) & (uint32_t)( HW_REGS_MASK ) );
	hps_xbee = virtual_base + ( (uint32_t)( ALT_LWFPGASLVS_OFST + FIFOED_AVALON_UART_BASE ) & (uint32_t)( HW_REGS_MASK ) );

	//Init memmory laser
	initMemory(hps_laser);

	//Write on LCD

	hide_cursor_lcd();
	clear_lcd();
	blacklight_on_lcd();
	set_courser_lcd(1, 1);

	write_data_lcd(text_1, sizeof(text_1));

	usleep(700*1000);

	do{

		key = read_key_lcd();

	}while(key != 0x0800);

	key = 0;
	clear_lcd();
	set_courser_lcd(1, 1);
	write_data_lcd(text_2, sizeof(text_2));

	usleep(700*1000);

	do{

		key = read_key_lcd();

		if(key == 0x0A00){

			clear_lcd();
			blacklight_off_lcd();

			if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
				printf( "ERROR: munmap() failed...\n" );
				close( memmory );
				return 7;
			}

			close(memmory);

			return 0;
		}

	}while(key != 0x0800);

	key = 0;
	clear_lcd();
	set_courser_lcd(1, 1);
	write_data_lcd(text_3, sizeof(text_3));

	usleep(700*1000);

	while(key != 0x0A00){

		key = read_key_lcd();

		switch (key){

			case KEY_1:
				key_1_fahren(hps_saber);
				clear_lcd();
				write_data_lcd(text_3, sizeof(text_3));
			break;

			case KEY_2:
				key_2_fahren(hps_saber);
				clear_lcd();
				write_data_lcd(text_3, sizeof(text_3));
			break;

			case KEY_3:
				key_3_fahren(hps_saber);
				clear_lcd();
				write_data_lcd(text_3, sizeof(text_3));
			break;

			case KEY_4:
				key_4_senden(hps_laser, hps_xbee);
				clear_lcd();
				write_data_lcd(text_3, sizeof(text_3));
			break;

			default:
				NULL;
			break;
		}

		usleep(100*1000);

	};

	clear_lcd();
	blacklight_off_lcd();

	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( memmory );
		return 7;
	}

	close(memmory);

	return 0;

}
