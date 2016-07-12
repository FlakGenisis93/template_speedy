/*
 * srf08.h
 *
 *  Created on: 11.07.2016
 *      Author: Urban
 */

#ifndef SRF08_H_
#define SRF08_H_

#include <stdint.h>

#include "i2c.h"

#define SRF_HL	0x71
#define SRF_V	0x72
#define SRF_HR	0x73

uint8_t read_version_srf08(uint8_t adresse_srf);
uint8_t measure_distance_srfx_zoll(uint8_t adresse_srf);
uint8_t measure_distance_srfx_cm(uint8_t adresse_srf);
uint8_t measure_distance_srfx_us(uint8_t adresse_srf);
uint8_t measure_aan_zoll(void);
uint8_t measure_aan_cm(void);
uint8_t measure_aan_us(void);
uint8_t read_lumen_srfx(uint8_t adresse_srf);
uint16_t read_data_srfx(uint8_t adresse_srf);
uint8_t read_all_data_srfx(uint8_t adresse_srf, uint16_t werte_srf[17]);
uint16_t read_data_einheit_aan_srfx(uint8_t adresse_srf);
uint8_t read_data_aan_srfx(uint8_t adresse_srf, uint16_t werte_aan[14]);
uint8_t read_all_data_aan_srfx(uint8_t adresse_srf, uint16_t *wert_einheit, uint16_t werte_aan[14]);

#endif /* SRF08_H_ */
