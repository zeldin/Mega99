typedef enum {
  SDCARD_REMOVED,
  SDCARD_INVALID,
  SDCARD_SD1,
  SDCARD_SD2,
  SDCARD_SDHC
} sdcard_type_t;

extern uint32_t sdcard_status(void);
extern sdcard_type_t sdcard_activate(void);
