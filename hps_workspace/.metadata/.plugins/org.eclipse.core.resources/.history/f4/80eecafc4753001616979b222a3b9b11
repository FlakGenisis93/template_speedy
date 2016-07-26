#ifndef SPEEDY_H_
#define SPEEDY_H_

#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#include "hps_0.h"
#include "hwlib.h"

#include "i2c.h"
#include "lcd.h"
#include "motor_modul_mm.h"
#include "xbee.h"

#include "adxl345.h"
#include "hmc6343.h"
#include "itg3200.h"
#include "laser_include.h"
#include "max11613.h"
#include "srf08.h"
#include "tpa81.h"

#define HW_REGS_BASE 	ALT_STM_OFST
#define HW_REGS_SPAN 	0x04000000
#define HW_REGS_MASK	HW_REGS_SPAN - 1

uint8_t init_speedy(void);


#endif /* SPEEDY_H_ */
