#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)

#define CPUROMH ((uint8_t *)(void *)0x80010000)
#define CPUROML ((uint8_t *)(void *)0x80011000)

#define FLUSH do { __asm__("" : : : "memory"); } while(0)
