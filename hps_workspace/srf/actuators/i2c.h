#ifndef I2C_H_
#define I2C_H_

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#define HW_REGS_BASE 	ALT_STM_OFST
#define HW_REGS_SPAN 	0x04000000
#define HW_REGS_MASK	HW_REGS_SPAN - 1

#define I2C_1		0xFFC05000
#define I2C_2		0xFFC06000
#define ic_con		0x00000000
#define ic_enable	0x0000006C


int init_i2c(uint32_t i2c_dev);
uint32_t read_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length);
uint32_t write_i2c(uint32_t i2c, uint8_t slave_adress, uint8_t data[], uint8_t length);

#endif /* I2C_H_ */
