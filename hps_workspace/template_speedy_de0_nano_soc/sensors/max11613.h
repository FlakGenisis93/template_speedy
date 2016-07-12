#ifndef MAX11613_H_
#define MAX11613_H_

#include <stdint.h>
#include "i2c.h"

#define ADDR_MAX11613	0x34

uint8_t write_setup_byte(void);
uint8_t write_config_byte(void);
uint8_t read_data_max11613(uint8_t bytes, uint8_t data_max[]);

#endif /* MAX11613_H_ */
