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
