#include "ADXL345.h"
#include <stdint.h>
#include <stdbool.h>

// api for register access, defined in main.c
bool ADXL345_REG_WRITE(int file, uint8_t address, uint8_t value);
bool ADXL345_REG_READ(int file, uint8_t address,uint8_t *value);
bool ADXL345_REG_MULTI_READ(int file, uint8_t readaddr,uint8_t readdata[],uint8_t len);



#define DATA_READY_TIMEOUT  (alt_ticks_per_second()/3)



bool ADXL345_Init(){

    bool bSuccess;

    int file;
    const char *filename = "/dev/i2c-0";

    // open bus
    if ((file = open(filename, O_RDWR)) < 0) {
    	/* ERROR HANDLING: you can check errno to see what went wrong */
    	   perror("Failed to open the i2c bus of gsensor");
    	   return -1;
    }


    // init
    // gsensor i2c address: 101_0011
    int addr = 0b01010011;
    if (ioctl(file, I2C_SLAVE, addr) < 0) {
    	printf("Failed to acquire bus access and/or talk to slave.\n");
    	/* ERROR HANDLING; you can check errno to see what went wrong */
    	  return -1;
    }

   
    // +- 2g range, 10 bits
    bSuccess = ADXL345_REG_WRITE(file, ADXL345_REG_DATA_FORMAT, XL345_RANGE_2G | XL345_FULL_RESOLUTION);
 
        
    //Output Data Rate: 50Hz
    if (bSuccess){
        bSuccess = ADXL345_REG_WRITE(file, ADXL345_REG_BW_RATE, XL345_RATE_50); // 50 HZ
    }
    
            
        
    //INT_Enable: Data Ready
    if (bSuccess){   
        bSuccess = ADXL345_REG_WRITE(file, ADXL345_REG_INT_ENALBE, XL345_DATAREADY);
    }
    
    // stop measure
    if (bSuccess){
        bSuccess = ADXL345_REG_WRITE(file, ADXL345_REG_POWER_CTL, XL345_STANDBY);
    }

    // start measure
    if (bSuccess){
        bSuccess = ADXL345_REG_WRITE(file, ADXL345_REG_POWER_CTL, XL345_MEASURE);
        
    }
    
    close(file);
            
    return bSuccess;    
        
}


  

bool ADXL345_IsDataReady(){
    bool bReady = false;
    uint8_t data8;
    int file;
	const char *filename = "/dev/i2c-0";

	// open bus
	if ((file = open(filename, O_RDWR)) < 0) {
		/* ERROR HANDLING: you can check errno to see what went wrong */
       	perror("Failed to open the i2c bus of gsensor");
       	exit(1);
    }


    // init
   	// gsensor i2c address: 101_0011
   	int addr = 0b01010011;
   	if (ioctl(file, I2C_SLAVE, addr) < 0) {
   		printf("Failed to acquire bus access and/or talk to slave.\n");
   		/* ERROR HANDLING; you can check errno to see what went wrong */
   		exit(1);
   	}
    
    if (ADXL345_REG_READ(file, ADXL345_REG_INT_SOURCE,&data8)){
        if (data8 & XL345_DATAREADY)
            bReady = true;
    }

    close(file);
    
    return bReady;
}



bool ADXL345_XYZ_Read(uint16_t szData16[3]){
    bool bPass;
    uint8_t szData8[6];
    int file;
    const char *filename = "/dev/i2c-0";

    // open bus
    if ((file = open(filename, O_RDWR)) < 0) {
    	/* ERROR HANDLING: you can check errno to see what went wrong */
    	perror("Failed to open the i2c bus of gsensor");
    	exit(1);
    }


    // init
	// gsensor i2c address: 101_0011
	int addr = 0b01010011;
	if (ioctl(file, I2C_SLAVE, addr) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	}


    bPass = ADXL345_REG_MULTI_READ(file, 0x32, (uint8_t *)&szData8, sizeof(szData8));
    if (bPass){
        szData16[0] = (szData8[1] << 8) | szData8[0]; 
        szData16[1] = (szData8[3] << 8) | szData8[2];
        szData16[2] = (szData8[5] << 8) | szData8[4];
    }        
    
    close(file);

    return bPass;
}

bool ADXL345_IdRead(uint8_t *pId){

	int file;
	const char *filename = "/dev/i2c-0";

	// open bus
	if ((file = open(filename, O_RDWR)) < 0) {
		/* ERROR HANDLING: you can check errno to see what went wrong */
	    perror("Failed to open the i2c bus of gsensor");
	    exit(1);
	}


	// init
	// gsensor i2c address: 101_0011
	int addr = 0b01010011;
	if (ioctl(file, I2C_SLAVE, addr) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
	  	exit(1);
	}

    bool bPass;
    bPass = ADXL345_REG_READ(file, ADXL345_REG_DEVID, pId);
    
    close(file);

    return bPass;
}


