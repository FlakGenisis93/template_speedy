#include "gsensor_nano.h"

#define ADXL345_REG_DEVID       0x00


bool ADXL345_REG_WRITE(int file, uint8_t address, uint8_t value){
	bool bSuccess = false;
	uint8_t szValue[2];
	
	// write to define register
	szValue[0] = address;
	szValue[1] = value;
	if (write(file, &szValue, sizeof(szValue)) == sizeof(szValue)){
			bSuccess = true;
	}		
	
	return bSuccess;		
}

bool ADXL345_REG_READ(int file, uint8_t address,uint8_t *value){
	bool bSuccess = false;
	uint8_t Value;
	
	// write to define register
	if (write(file, &address, sizeof(address)) == sizeof(address)){
	
		// read back value
		if (read(file, &Value, sizeof(Value)) == sizeof(Value)){
			*value = Value;
			bSuccess = true;
		}
	}		
	
	return bSuccess;	
}

bool ADXL345_REG_MULTI_READ(int file, uint8_t readaddr,uint8_t readdata[], uint8_t len){
	bool bSuccess = false;

	// write to define register
	if (write(file, &readaddr, sizeof(readaddr)) == sizeof(readaddr)){
		// read back value
		if (read(file, readdata, len) == len){
			bSuccess = true;
		}
	}			
	return bSuccess;
}





uint8_t hps_gsensor_messen(uint8_t messungen){
	
	uint8_t id;
	bool bSuccess;
	const int mg_per_digi = 4;
	uint16_t szXYZ[3];
	int cnt = 0;


    // configure accelerometer as +-2g and start measure
    bSuccess = ADXL345_Init();
    if (bSuccess){
        // dump chip id
        bSuccess = ADXL345_IdRead(&id);
        if (bSuccess)
            printf("id=%02Xh\r\n", id);
    }        
    
    
    while(bSuccess && (cnt < messungen)){
        if (ADXL345_IsDataReady()){
            bSuccess = ADXL345_XYZ_Read(szXYZ);
            if (bSuccess){
	              cnt++;
                printf("[%d]X=%d mg, Y=%d mg, Z=%d mg\r\n", cnt,(int16_t)szXYZ[0]*mg_per_digi, (int16_t)szXYZ[1]*mg_per_digi, (int16_t)szXYZ[2]*mg_per_digi);
                // show raw data, 
                //printf("X=%04x, Y=%04x, Z=%04x\r\n", (alt_u16)szXYZ[0], (alt_u16)szXYZ[1],(alt_u16)szXYZ[2]);
                usleep(1000*1000);
            }
        }
    }
    
    if (!bSuccess)
        printf("Failed to access accelerometer\r\n");

	return 0;
	
}


