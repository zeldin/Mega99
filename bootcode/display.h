#include <stdint.h>
#include <stddef.h>

extern void display_init(void);
extern void printstrn(uint32_t offs, const char *s, size_t n);
extern void printhex(uint32_t offs, uint32_t v);

#define SCREENPOS(y, x) (((y) << 5) | (x))
