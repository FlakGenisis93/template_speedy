#ifndef HMC6343_H_
#define HMC6343_H_

#include <stdint.h>

#include "i2c.h"

#define ADDR_HMC	0x19

uint8_t write_cmd_hmc(uint8_t command);
uint8_t post_heading_data(void);
uint8_t read_data_hmc(uint8_t data_hmc[]);


#endif /* HMC6343_H_ */
