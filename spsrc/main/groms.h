#define GROMS_USE_DMA 1

extern uint8_t *groms_allocate_grom(uint16_t sets, uint16_t base);
extern void groms_free_grom_range(uint16_t sets, uint16_t base, size_t size);
extern void groms_update_garbage(uint8_t *grom);
extern void groms_init(void);
