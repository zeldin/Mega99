#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)

#define CPUROMH ((uint8_t *)(void *)0x80010000)
#define CPUROML ((uint8_t *)(void *)0x80011000)

#define GROM_CTRL ((uint8_t *)(void *)0x80020000)
#define CARTROM_CTRL ((uint8_t *)(void *)0x80030000)

#define GROM(n) ((uint8_t *)(void *)(0x80100000+(n)*0x2000))
#define CARTROM ((uint8_t *)(void *)0x80200000)

#define FLUSH do { __asm__("" : : : "memory"); } while(0)
