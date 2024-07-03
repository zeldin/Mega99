extern void display_init(void);
extern void display_putc(char c);
extern void display_puts(const char *str);
extern void display_puthex(uint32_t v);
extern void display_vprintf(const char *fmt, va_list va)
  __attribute__ ((__format__ (__printf__, 1, 0)));
extern void display_printf(const char *fmt, ...)
  __attribute__ ((__format__ (__printf__, 1, 2)));
