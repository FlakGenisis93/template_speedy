#ifndef ITG3200_H_
#define ITG3200_H_

#include <stdint.h>

#include "i2c.h"

#define ADDR_ITG	0x69

uint8_t read_version_itg(void);
uint16_t read_temp_itg(void);


#endif /* ITG3200_H_ */
