#define QSPI ((uint8_t *)(void *)0xc0000000)

#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)

#define CPUROMH ((uint8_t *)(void *)0x80010000)
#define CPUROML ((uint8_t *)(void *)0x80011000)

#define GROM_CTRL ((uint8_t *)(void *)0x80020000)
#define CARTROM_CTRL ((uint8_t *)(void *)0x80030000)

#define GROM(n) ((uint8_t *)(void *)(0x80100000+(n)*0x2000))
#define CARTROM ((uint8_t *)(void *)0x80200000)
#define SPEECHROM ((uint8_t *)(void *)0x80300000)

struct mem_regs_fdc {
  uint8_t mounted_wp;
  uint8_t rd_wr;
  uint8_t ack;
  uint8_t img_shape;
  uint8_t track_side;
  uint8_t sector;
  uint8_t cmd;
};

#define FDCROM ((uint8_t *)(void *)0x80800000)
#define FDCBUF ((uint8_t *)(void *)0x80802000)
#define FDCREGS (*(volatile struct mem_regs_fdc *)(void *)0x80803000)

#define FLUSH do { __asm__("" : : : "memory"); } while(0)
