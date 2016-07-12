/*
 * xbee.h
 *
 *  Created on: 06.07.2016
 *      Author: Urban
 */

#ifndef XBEE_H_
#define XBEE_H_

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>

#include "hps_0.h"
#include "hwlib.h"

#define HW_REGS_BASE	ALT_STM_OFST
#define HW_REGS_SPAN 	0x04000000
#define HW_REGS_MASK 	HW_REGS_SPAN - 1

#define REG_W_BEFEHL	0x0
#define REG_W_ZELLE		0x1
#define REG_W_INIT		0x2

#define REG_R_CHAR		0x0
#define REG_R_BEFEHL	0x1
#define REG_R_ADDR		0x2
#define REG_R_INIT		0x3

__inline__ uint8_t XBEE_FRAME_CHECKSUM(uint8_t* frameData, uint8_t lenghtOfDataInBytes);
uint8_t create_xbee_frame(uint16_t xbee_addr, uint8_t *xbee_frame, uint8_t daten[], uint16_t length);
uint8_t xbee_tx(uint16_t xbee_addr, uint8_t daten[], uint16_t length);
uint8_t xbee_rx(void);

#endif /* XBEE_H_ */
