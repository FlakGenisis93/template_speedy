#ifndef __LASER_INCLUDE_H__
#define __LASER_INCLUDE_H__

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#include "../src/hps_0.h"
#include "hwlib.h"
#include "time.h"
#include "laser.h"

#define HW_REGS_BASE 	ALT_STM_OFST
#define HW_REGS_SPAN 	0x04000000
#define HW_REGS_MASK	HW_REGS_SPAN - 1

#endif
