/**
 ******************************************************************************
 * @file    motor_modul.h
 * @author  BoE. Lt. Kluge Florian
 * @version V0.0.5
 * @date    28.04.2016
 * @brief   Befehle fuer motor_modul - Header
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
 ********************************************************************************
 * @brief
 * <h2><center>&copy; COPYRIGHT 2012 - 2016 UniBwM ETTI WE 4</center></h2>
 ********************************************************************************
 */



#include <stdio.h>
#include "string.h"
#include "stdint.h"

//#include "sensors/gyroPSitg3200.h"


#ifndef MOTOR_MODUL_H_
#define MOTOR_MODUL_H_

#define DRIVE 		0x8001	//dez: 32769
#define DRIVE_TURN 	0x8002 	//dez: 32770
#define DRIVE_CURVE 0x8003	//deZ: 32771



/**
  * @brief		int16_t getGyro_result()
  * @details	Funktion die einen Wert(hier: Z-Wert) vom Gyro holt.
  * @param		None
  * @retval		int16_t result, Wert vom Gyro
  */
int16_t getGyro_result(){
  uint8_t i2c_status;
  uint8_t scmd;
  uint8_t val;
  int16_t result = 0; //uint16_t result;

  scmd=Gyro_ZOUT_HIGH;
  i2c_status = os_i2c_Transceive(I2C_CHAN0, I2C_Gyro, &scmd, 1, &val, 1);
  result=(((int)val)<<8);
  scmd=Gyro_ZOUT_LOW;
  i2c_status |= os_i2c_Transceive(I2C_CHAN0, I2C_Gyro, &scmd, 1, &val, 1);
  result+=(int)val;
  result=(int16_t)(result/14.375);

  return result; // grad/sec
}

/**
  * @brief		void drive(uint8_t speed, int16_t distance)
  * @details	Funktion die ueber das Interface den Fahrbefehl mit
  * 			entsprechenden Parametern aufruft.
  * @param		uint8_t speed:		Geschwindigkeit
  * 			int16_t distance:	Distanz die zurueckgelegt werden soll(+/-)
  * @retval		None
  */
void drive(uint8_t speed, int16_t distance){
	uint32_t done_flag = 0;

	if(distance < 0){
		distance = distance * -1;
		distance = distance + 32768;
	}

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 	//speed
	IOWR(MOTOR_MODUL_0_BASE,1,distance); //distance !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE); 	//command

	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		if(done_flag == 1){
			break;
		}
	}
}



void drive_turn(uint8_t speed, int16_t angle){
	int16_t gyro_result;
	uint32_t done_flag = 0;

	if(angle < 0){
		angle = angle * -1;
		angle = angle + 32768;
	}

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 		//speed
	IOWR(MOTOR_MODUL_0_BASE,2,angle); 		//angle !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE_TURN); 	//command

	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		IOWR(MOTOR_MODUL_0_BASE,5,gyro_result); //transmit

		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		if(done_flag == 1){
			break;
		}
	}
}



int16_t get_turn_offset(){
	int8_t count = 0;
	int16_t gyro_result;
	int16_t gyro_offset = 0;

	while(count <= 4){
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		gyro_offset = gyro_offset + gyro_result;
		count++;
		OSTimeDlyHMSM(0, 0, 0, 100);
	}
	if (gyro_offset >= 5){
		gyro_offset = gyro_offset / 5;
	}else{
		gyro_offset = 0;
	}
	return gyro_offset;
}



void drive_turn_w_offset(uint8_t speed, int16_t angle){
	int16_t gyro_result;
	int16_t offset;
	uint32_t done_flag = 0;
	offset = get_turn_offset();
	if(angle < 0){
		angle = angle * -1;
		angle = angle + 32768;
	}

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 		//speed
	IOWR(MOTOR_MODUL_0_BASE,2,angle); 		//angle !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE_TURN); 	//command

	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		IOWR(MOTOR_MODUL_0_BASE,5,(gyro_result-offset)); //transmit

		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		if(done_flag == 1){
			break;
		}
	}
}




/////////////////////////////////////TEST////////////////////////////////////////////////////////////////////////////////////////
static __inline__ void curve(){
					IOWR(MOTOR_MODUL_0_BASE,0,25); 		//transmit 						Geschwindigkeit:	25
					IOWR(MOTOR_MODUL_0_BASE,2,90); 		//transmit						Winkel:				90
					IOWR(MOTOR_MODUL_0_BASE,3,2); 		//transmit						radius:				look up tabelle
					IOWR(MOTOR_MODUL_0_BASE,4,32775); 	//transmit						Befehl:		 		kurve
}


static __inline__ void send_driveback(){
					IOWR(MOTOR_MODUL_0_BASE,0,25); //transmit //25 geht!!!!!!!!!!!	Geschwindigkeit:	25
					IOWR(MOTOR_MODUL_0_BASE,1,33368); //transmit						Strecke:			60cm
					IOWR(MOTOR_MODUL_0_BASE,4,32769); //transmit						Befehl:		 		Fahren
}

//erkennung von negativen Zahlen und umwandlung in einerkopliment(auch in vhdl realisirbar, allerdings nur mit min 2 konvertierungen, ist also nicht besser...)
void drive_test(uint8_t speed, int16_t distance){
	if(distance < 0){
		distance = distance * -1;
		distance = distance + 32768;

	}
		IOWR(MOTOR_MODUL_0_BASE,0,speed); 	//speed
		IOWR(MOTOR_MODUL_0_BASE,1,distance); //distance !+/-!
		IOWR(MOTOR_MODUL_0_BASE,4,DRIVE); 	//command

}


void gyro_test(){
  Gyro_Result_t gyroResult;
  uint8_t i2c_status;
  char txt[30]="ERROR";

  i2c_status = getGyro_Result(&gyroResult);

  //if(i2c_status!=0x0){LCDwrite(&txt[0],5);return;}
  //sprintf((char *)&txt[0],"X:%4d   %4d       ",gyroResult.XYZ[0],gyroResult.XYZ[0]);
  //LCDwrite(&txt[0],20);
  //sprintf((char *)&txt[0],"Y:%4d   %4d       ",gyroResult.XYZ[1],gyroResult.XYZ[1]);
  // LCDwrite(&txt[0],20);
  sprintf((char *)&txt[0],"Z:%4d   %4d T:%4d",gyroResult.XYZ[2],gyroResult.XYZ[2],gyroResult.temperature);
  LCDwrite(&txt[0],20);
}




void drive_regler(uint8_t speed, int16_t distance){
	uint32_t done_flag = 0;
	uint16_t E1 =0;
	uint16_t E2 =0;

	if(distance < 0){
		distance = distance * -1;
		distance = distance + 32768;
	}

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 	//speed
	IOWR(MOTOR_MODUL_0_BASE,1,distance); //distance !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE_TURN); 	//command

	while(1){
		OSTimeDlyHMSM(0, 0, 0, 50);
		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		E1 = IORD(MOTOR_MODUL_0_BASE,1);
		E2 = IORD(MOTOR_MODUL_0_BASE,2);

		printf("E1: %i \n",E1);
		printf("	E2: %i \n",E2);
		if(done_flag == 1){
			break;
		}

	}
}


void drive_in_steps(){

	int16_t gyro_result;
	int16_t offset;
	uint32_t done_flag = 0;
	int16_t angle = 180;
	int8_t count = 0;
	uint8_t speed = 25;


	offset = get_turn_offset();

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 		//speed
	IOWR(MOTOR_MODUL_0_BASE,2,angle); 		//angle !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE_TURN); 	//command



	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		IOWR(MOTOR_MODUL_0_BASE,5,(gyro_result-offset)); //transmit

		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		if(done_flag == 1){
			break;
		}
	}
}


void drive_curve_steps(){

	int16_t gyro_result;
	int16_t offset;
	uint32_t done_flag = 0;
	int16_t angle = 180;
	uint8_t speed = 130;

	int16_t winkel_part;
	int16_t winkel_sum;


	offset = get_turn_offset();

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 		//speed
	IOWR(MOTOR_MODUL_0_BASE,2,angle); 		//angle !+/-!
	IOWR(MOTOR_MODUL_0_BASE,4,32775); 	//command



	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		IOWR(MOTOR_MODUL_0_BASE,5,(gyro_result-offset)); //transmit

		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		winkel_part = IORD(MOTOR_MODUL_0_BASE,3);
		winkel_sum = IORD(MOTOR_MODUL_0_BASE,4);

		printf("Gyro: %i \n",gyro_result);
		printf("Part: %i \n",winkel_part);
		printf("Sum : %i \n",winkel_sum);

		if(done_flag == 1){
			break;
		}
	}
}

void drive_curve_steps_test(){

	int16_t gyro_result;
	int16_t offset;
	uint32_t done_flag = 0;
	int16_t angle = 180; //momentan noch FIX
	uint8_t speed = 130;
	int16_t radius = 600;
	int16_t resolution = 10;
	int16_t circle_part_m1 = 0;
	int16_t circle_part_m2 = 0;

	int16_t winkel_part;
	int16_t winkel_sum;

	int8_t turn = 1;//0-left 1-right

	if(angle < 0){
		angle = angle * -1;
		angle = angle + 32768;
		turn = 0;
	}


	if(turn == 1){
		circle_part_m1 = (int16_t)((radius + 256)*3.77/resolution);

		circle_part_m2 = (int16_t)(radius *3.77/resolution);
	}else{
		circle_part_m2 = (int16_t)((radius + 256)*3.77/resolution);

		circle_part_m1 = (int16_t)(radius *3.77/resolution);
	}

	offset = get_turn_offset();

	IOWR(MOTOR_MODUL_0_BASE,0,speed); 		//speed
	IOWR(MOTOR_MODUL_0_BASE,2,angle); 		//angle !+/-!
	IOWR(MOTOR_MODUL_0_BASE,3,radius);
	IOWR(MOTOR_MODUL_0_BASE,6,resolution);
	IOWR(MOTOR_MODUL_0_BASE,7,circle_part_m1);
	IOWR(MOTOR_MODUL_0_BASE,8,circle_part_m2);
	IOWR(MOTOR_MODUL_0_BASE,4,DRIVE_CURVE); 	//command



	while(1){
		OSTimeDlyHMSM(0, 0, 0, 100);
		gyro_result = getGyro_result();
		if (gyro_result < 0){
			gyro_result = gyro_result *-1;
		}
		IOWR(MOTOR_MODUL_0_BASE,5,(gyro_result-offset)); //transmit

		done_flag = IORD(MOTOR_MODUL_0_BASE,0); //done_flag lesen
		winkel_part = IORD(MOTOR_MODUL_0_BASE,3);
		winkel_sum = IORD(MOTOR_MODUL_0_BASE,4);

		printf("Gyro: %i \n",gyro_result);
		printf("Part: %i \n",winkel_part);
		printf("Sum : %i \n",winkel_sum);

		if(done_flag == 1){
			break;
		}
	}
}
/////////////////////////////////////TEST////////////////////////////////////////////////////////////////////////////////////////




















#endif /* MOTOR_MODUL_H_ */
