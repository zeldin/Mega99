struct overlay_window {
  uint16_t window_id;
  uint16_t base;
  uint16_t lineoffs;
  uint16_t current_w;
  uint16_t current_h;
  uint16_t min_w;
  uint16_t min_h;
  uint16_t max_w;
  uint16_t max_h;
  uint16_t background_color;
  uint16_t border_color;
  uint16_t text_color;
  uint16_t cursor_y;
  uint16_t cursor_x;
};

extern struct overlay_window console_window;

extern bool overlay_window_is_shown(struct overlay_window *ow);
extern void overlay_window_set_shown(struct overlay_window *ow, bool shown);
extern void overlay_window_clear_line(struct overlay_window *ow, uint16_t line,
				      const char *pattern);
extern void overlay_window_clear(struct overlay_window *ow);
extern void overlay_window_scroll(struct overlay_window *ow);
extern void overlay_window_resize(struct overlay_window *ow,
				  uint16_t w, uint16_t h);
extern void overlay_window_putchar(struct overlay_window *ow, uint8_t ch);
extern void overlay_window_newline(struct overlay_window *ow);
extern void overlay_console_putc(int fd, char ch);
extern void overlay_task(void);
extern void overlay_init(void);
