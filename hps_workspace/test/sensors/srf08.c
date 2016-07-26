/**
  *******************************************************************************************************************
  * @file      	srf08.c
  * @author    	B. Eng. Urban Conrad
  * @version   	V1.0
  * @date      	14.07.2016
  * @copyright 	2009 - 2016 UniBw M - ETTI - Institut 4
  * @brief   	Functions to control SRF08 modul
  *******************************************************************************************************************
  * @par History:
  *  @details V1.0.0 14.07.2016 Urban Conrad
  *           - Initial version
  *******************************************************************************************************************
  */
  
//	I	N	C	L	U	D	E	S
 
#include "srf08.h"

//	F	U	N	K	T	I	O	N	E	N

uint8_t read_version_srf08(uint8_t adresse_srf){

	uint8_t version = 0;

	//Festlegen des zu lesenden Registers
	uint8_t cmd_reg_0 = {0};

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &cmd_reg_0, 1) != 1)
		return -1;

	//Lesen der Versionsnummer
	if( read_i2c(I2C_1, adresse_srf, &version, 1) != 1)
		return -1;

	//Rueckgabe der Verison
	return version;
}

uint8_t measure_distance_srfx_zoll(uint8_t adresse_srf){

	//Anlegen des Registers mit den Befehlen fuer Messung in Zoll
	uint8_t command[] = {0x0, 0x50};

	//Starten der Messung in Zoll
	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_distance_srfx_cm(uint8_t adresse_srf){

	//Anlegen des Registers mit den Befehlen fuer Messung in cm
	uint8_t command[] = {0x0, 0x51};

	//Starten der Messung in cm
	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_distance_srfx_us(uint8_t adresse_srf){

	//Anlegen des Registers mit den Befehlen fuer Messung in us
	uint8_t command[] = {0x0, 0x52};

	//Starten der Messung in us
	if(write_i2c(I2C_1, adresse_srf, command, 2) == 2)
		return 0;

	return 1;

}


uint8_t measure_aan_zoll(void){

	//Anlegen des Registers mit den Befehlen fuer AAN Messung in Zoll
	uint8_t command[] = {0x0, 0x53};
	
	//Starten der AAN Messung in Zoll
	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_aan_cm(void){

	//Anlegen des Registers mit den Befehlen fuer AAN Messung in cm
	uint8_t command[] = {0x0, 0x54};

	//Starten der AAN Messung in cm
	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t measure_aan_us(void){

	//Anlegen des Registers mit den Befehlen fuer AAN Messung in us
	uint8_t command[] = {0x0, 0x55};

	//Starten der AAN Messung in us
	if(write_i2c(I2C_1, 0x00, command, 2) == 2)
		return 0;

	return 1;

}

uint8_t read_lumen_srfx(uint8_t adresse_srf){

	uint8_t lumen = 0;
	uint8_t reg_lumen = 1;

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &reg_lumen, 1) != 1)
		return -1;

	//Lesen der Lumen
	if(read_i2c(I2C_1, 0x71, &lumen, 1) != 1)
		return -1;

	//Rueckgabe der Lumen
	return lumen;
}

uint16_t read_data_srfx(uint8_t adresse_srf){

	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[] = {0, 0};
	uint16_t wert_srf;

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1) != 1)
		return -1;

	//Liest nur die kuerzeste Entfernung aus
	if( read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
		return -1;

	//Schreiben der low 8 Bit in wert_srf
	wert_srf = entfernung[1];

	//Schreiben der high 8 Bit in wert_srf
	wert_srf = wert_srf | (entfernung[0] << 8);

	//Rueckgabe der Entfernung
	return wert_srf;

}

uint8_t read_all_data_srfx(uint8_t adresse_srf, uint16_t werte_srf[]){

	uint8_t i = 0;
	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[2];

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1) != 1)
		return -1;

	do {

		//Array entfernung wieder auf 0 setzen
		entfernung[0] = 0;
		entfernung[1] = 0;

		//lesen der Entfernung aus dem Register
		if(read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
			return -1;

		//Schreiben der low 8 Bit in wert_srf[i]
		werte_srf[i] = entfernung[1];

		//Schreiben der high 8 Bit in wert_srf[i]
		werte_srf[i] = werte_srf[i] | (entfernung[0] << 8);

		//Falls Wert gelsen wurde i erhoehen
		if((entfernung[1] != 0) || (entfernung[0] != 0))
			i++;

		//Falls Array entfernung != 0, wiederhole
	} while ( (entfernung[1] != 0) || (entfernung[0] != 0) );

	//Rueckgabe der Anzahl der gelesenen Werte
	return i;
}

uint16_t read_data_einheit_aan_srfx(uint8_t adresse_srf){

	uint8_t reg_echo_byte = 2;
	uint8_t entfernung[] = {0, 0};
	uint16_t wert_srf;

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &reg_echo_byte, 1) != 1)
		return -1;

	//Lesen der Kuerzesten Entfernung in der Einheit wie die Messung ausgeloest wurde
	if( read_i2c(I2C_1, adresse_srf, entfernung, 2) != 2)
		return -1;

	//Schreiben der low 8 Bit in wert_srf
	wert_srf = entfernung[1];

	//Schreiben der high 8 Bit in wert_srf
	wert_srf = wert_srf | (entfernung[0] << 8);

	//Rueckgabe der Entfernung
	return wert_srf;

}

uint8_t read_data_aan_srfx(uint8_t adresse_srf, uint16_t werte_aan[]){

	uint8_t i;
	uint8_t reg_aan_data = 4;
	uint8_t entfernung[28];

	//Registernr an Modul schreiben
	if(write_i2c(I2C_1, adresse_srf, &reg_aan_data, 1) != 1)
		return -1;

	//Lesen der AAN Daten 
	if(read_i2c(I2C_1, adresse_srf, entfernung, 28) != 2)
		return -1;

	//Speichern der AAN Daten in werte_aan
	for( i = 0; i < 14; i++){
		
		//Schreiben der low 8 Bit in werte_aan[i]
		werte_aan[i] = entfernung[1 + i*2];

		//Schreiben der high 8 Bit in werte_aan[i]
		werte_aan[i] = werte_aan[i] | (entfernung[0 + i*2] << 8);

	}

	return 0;
}

uint8_t read_all_data_aan_srfx(uint8_t adresse_srf, uint16_t *wert_einheit, uint16_t werte_aan[]){

	uint8_t check = 0;
	
	//Lesen der Kuerzesten Entfernung in der gewuenschten Einheit
	check = read_data_einheit_aan_srfx(adresse_srf);
	
	if(check != -1){
		*wert_einheit = check;
	} else {
		return -1;
	}
		

	//AAN Daten lesen
	if(read_data_aan_srfx(adresse_srf, werte_aan) == -1)
		return -2;

	return 0;
}


