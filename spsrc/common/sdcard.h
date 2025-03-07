typedef enum {
  SDCARD_REMOVED,
  SDCARD_INVALID,
  SDCARD_SD1,
  SDCARD_SD2,
  SDCARD_SDHC
} sdcard_type_t;

#define SDCARD_STATUS_PRESENT   1u
#define SDCARD_STATUS_WRITEPROT 2u
#define SDCARD_STATUS_CHANGED   4u

extern uint32_t sdcard_status(void);
extern sdcard_type_t sdcard_activate(void);
extern bool sdcard_read_block(uint32_t blkid, uint8_t *ptr);
#ifndef BOOTCODE
extern bool sdcard_write_block(uint32_t blkid, const uint8_t *ptr);
#endif
extern unsigned sdcard_num_cards(void);
extern unsigned sdcard_get_card_number(void);
extern void sdcard_set_card_number(unsigned n);
