#ifndef LCD_H_
#define LCD_H_

#include "i2c.h"

#define LCD03_ADRESS	0x63

uint32_t read_register_lcd(uint8_t data[4]);
uint16_t read_key_lcd(void);
uint8_t read_free_fifo_lcd(void);
uint8_t write_data_lcd(uint8_t data[], uint8_t length);
uint8_t clear_lcd(void);
uint8_t set_courser_lcd(uint8_t line, uint8_t column);
uint8_t blacklight_on_lcd(void);
uint8_t blacklight_off_lcd(void);

#endif /* LCD_H_ */
