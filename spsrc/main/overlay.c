#include "global.h"
#include "overlay.h"
#include "regs.h"
#include "timer.h"

static uint32_t overlay_console_error_auto_hide_time = S_TO_TICKS(10);
static uint32_t overlay_console_normal_auto_hide_time = S_TO_TICKS(3);

static const uint8_t font_8x16[] = {
#include "font_8x16.h"
};

struct overlay_window console_window = {
  .window_id = 0,
  .min_w = 16,
  .min_h = 3,
  .max_w = 66,
  .max_h = 26,
  .background_color = WINDOW_COLOR(1, 14),
  .border_color = WINDOW_COLOR(15, 14),
  .text_color = WINDOW_COLOR(1, 14)
};

struct overlay_window menu_window = {
  .window_id = 2,
  .min_w = 20,
  .min_h = 8,
  .max_w = 40,
  .max_h = 16,
  .background_color = WINDOW_COLOR(15, 4),
  .border_color = WINDOW_COLOR(10, 4),
  .text_color = WINDOW_COLOR(15, 4)
};

static uint32_t console_auto_hide = 0;

bool overlay_window_is_shown(struct overlay_window *ow)
{
  return REGS_OVERLAY.control & (8u >> ow->window_id);
}

void overlay_window_set_shown(struct overlay_window *ow, bool shown)
{
  if (shown)
    REGS_OVERLAY.control |= 8u >> ow->window_id;
  else
    REGS_OVERLAY.control &= ~(8u >> ow->window_id);
}

void overlay_window_clear_line(struct overlay_window *ow, uint16_t line,
			       const char *pattern)
{
  unsigned w;
  if (line >= ow->current_h || !(w = ow->current_w))
    return;
  if (!pattern)
    pattern = "\x81\x20\x81";
  uint16_t offs = ow->base + line*ow->lineoffs;
  uint16_t ch;
  if ((ch = *pattern++) == 0x20)
    ch |= ow->background_color;
  else
    ch |= ow->border_color;
  *(uint16_t*)&OVERLAY[offs] = ch;
  offs += 2;
  if ((ch = *pattern++) == 0x20)
    ch |= ow->background_color;
  else
    ch |= ow->border_color;
  if (w > 2)
    for (unsigned j = 2; j < w; j++) {
      *(uint16_t*)&OVERLAY[offs] = ch;
      offs += 2;
    }
  if (w > 1) {
    if ((ch = *pattern++) == 0x20)
      ch |= ow->background_color;
    else
      ch |= ow->border_color;
    *(uint16_t*)&OVERLAY[offs] = ch;
  }
}

void overlay_window_invert_line(struct overlay_window *ow, uint16_t line)
{
  unsigned w;
  if (line >= ow->current_h || (w = ow->current_w) < 3)
    return;
  uint16_t offs = ow->base + line*ow->lineoffs + 2;
  --w;
  while(--w) {
    uint8_t color = OVERLAY[offs];
    OVERLAY[offs] = (color >> 4) | (color << 4);
    offs += 2;
  }
}

void overlay_window_clear(struct overlay_window *ow)
{
  unsigned h;
  if (ow->current_w && (h = ow->current_h) > 2)
    for (unsigned i = 1; i+1 < h; i++)
      overlay_window_clear_line(ow, i, NULL);
}

void overlay_window_scroll(struct overlay_window *ow)
{
  unsigned h, w;
  if((h = ow->current_h) < 3 || (w = ow->current_w) < 3)
    return;
  uint16_t offs = ow->base + ow->lineoffs;
  for (unsigned i = 1; i+2 < h; i++) {
    memcpy(&OVERLAY[offs], &OVERLAY[offs+ow->lineoffs], w*2);
    offs += ow->lineoffs;
  }
  overlay_window_clear_line(ow, h-2, NULL);
}

void overlay_window_resize(struct overlay_window *ow, uint16_t w, uint16_t h)
{
  if (w < ow->min_w)
    w = ow->min_w;
  else if (w > ow->max_w)
    w = ow->max_w;
  if (w < ow->current_w) {
    /* Reduce width */
    uint16_t x = 33 - (w >> 1);
    REGS_OVERLAY.window[ow->window_id].x0 = x;
    REGS_OVERLAY.window[ow->window_id].x1 = x + w;
    if (w > 1 && ow->current_h > 0) {
      /* New right border */
      uint16_t offs = ow->base + (w-1)*2;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x87;
      offs += ow->lineoffs;
      for (unsigned i = 2; i < ow->current_h; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x81;
	offs += ow->lineoffs;
      }
      if (ow->current_h > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8d;
    }
  } else if (w > ow->current_w) {
    /* Increase width */
    if (!ow->current_w && ow->current_h > 0) {
      /* New left border */
      uint16_t offs = ow->base;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x84;
      offs += ow->lineoffs;
      for (unsigned i = 2; i < ow->current_h; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x81;
	offs += ow->lineoffs;
      }
      if (ow->current_h > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8a;
    }
    if (w > 1 && ow->current_h > 0) {
      /* New right border */
      uint16_t offs = ow->base + (w-1)*2;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x87;
      offs += ow->lineoffs;
      for (unsigned i = 2; i < ow->current_h; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x81;
	offs += ow->lineoffs;
      }
      if (ow->current_h > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8d;
    }
    if (w > 2 && ow->current_h > 0) {
      /* Clear midriff */
      uint16_t offs = ow->base;
      for (unsigned i = 0; i < ow->current_h; i++) {
	uint16_t chr = (i == 0 || i+1 == ow->current_h ?
			0x80 | ow->border_color :
			0x20 | ow->background_color);
	for (unsigned j = (ow->current_w < 3? 1 : ow->current_w - 1);
	     j < w-1; j++)
	  ((uint16_t*)&OVERLAY[offs])[j] = chr;
	offs += ow->lineoffs;
      }
    }
    uint16_t x = 33 - (w >> 1);
    REGS_OVERLAY.window[ow->window_id].x0 = x;
    REGS_OVERLAY.window[ow->window_id].x1 = x + w;
  }
  ow->current_w = w;

  if (h < ow->min_h)
    h = ow->min_h;
  else if (h > ow->max_h)
    h = ow->max_h;
  if (h < ow->current_h) {
    /* Reduce height */
    uint16_t y = 13 - (h >> 1);
    REGS_OVERLAY.window[ow->window_id].y0 = y;
    REGS_OVERLAY.window[ow->window_id].y1 = y + h;
    if (h > 1 && w > 0) {
      /* New bottom border */
      uint16_t offs = ow->base + (h-1)*ow->lineoffs;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8a;
      offs += 2;
      for (unsigned i = 2; i < w; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x80;
	offs += 2;
      }
      if (w > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8d;
    }
  } else if (h > ow->current_h) {
    /* Increase height */
    if (!ow->current_h && w > 0) {
      /* New top border */
      uint16_t offs = ow->base;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x84;
      offs += 2;
      for (unsigned i = 2; i < w; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x80;
	offs += 2;
      }
      if (w > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x87;
    }
    if (h > 1 && w > 0) {
      /* New bottom border */
      uint16_t offs = ow->base + (h-1)*ow->lineoffs;
      *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8a;
      offs += 2;
      for (unsigned i = 2; i < w; i++) {
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x80;
	offs += 2;
      }
      if (w > 1)
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x8d;
    }
    if (h > 2 && w > 0) {
      /* Clear midriff */
      for (unsigned i = (ow->current_h < 3? 1 : ow->current_h - 1);
	   i < h-1; i++) {
	uint16_t offs = ow->base + i*ow->lineoffs;
	*(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x81;
	offs += 2;
	if (w > 2)
	  for (unsigned j = 2; j < w; j++) {
	    *(uint16_t*)&OVERLAY[offs] = ow->background_color | 0x20;
	    offs += 2;
	  }
	if (w > 1)
	  *(uint16_t*)&OVERLAY[offs] = ow->border_color | 0x81;
      }
    }
    uint16_t y = 13 - (h >> 1);
    REGS_OVERLAY.window[ow->window_id].y0 = y;
    REGS_OVERLAY.window[ow->window_id].y1 = y + h;
  }
  ow->current_h = h;
}

void overlay_window_putchar(struct overlay_window *ow, uint8_t ch)
{
  if (!ow->current_w || ow->cursor_x >= ow->current_w - 1)
    overlay_window_resize(ow, ow->cursor_x + 2, ow->current_h);
  if (ow->current_w < 3)
    return;
  if (ow->cursor_x >= ow->current_w - 1) {
    ow->cursor_x = 1;
    ow->cursor_y ++;
  }
  if (!ow->current_h || ow->cursor_y >= ow->current_h - 1)
    overlay_window_resize(ow, ow->current_w, ow->cursor_y + 2);
  if (ow->current_h < 3)
    return;
  while (ow->cursor_y >= ow->current_h - 1) {
    --ow->cursor_y;
    overlay_window_scroll(ow);
  }
  *(uint16_t *)&OVERLAY[ow->base+ow->cursor_y*ow->lineoffs+ow->cursor_x++*2] =
    ch | ow->text_color;
}

void overlay_window_newline(struct overlay_window *ow)
{
  ow->cursor_x = 1;
  ow->cursor_y ++;
}

static uint32_t overlay_console_error_auto_hide_time;
static uint32_t overlay_console_normal_auto_hide_time;

void overlay_console_putc(int fd, char ch)
{
  if (!console_window.base)
    return;
  if (!overlay_window_is_shown(&console_window)) {
    overlay_window_resize(&console_window,
			  console_window.min_w, console_window.min_h);
    overlay_window_clear(&console_window);
    console_window.cursor_x = 1;
    console_window.cursor_y = 1;
  }
  if (ch == '\n')
    overlay_window_newline(&console_window);
  else {
    console_window.text_color =
      (fd == 2? WINDOW_COLOR(6, 14) : WINDOW_COLOR(1, 14));
    overlay_window_putchar(&console_window, ch);
  }
  uint32_t hide_time = (fd == 2? overlay_console_error_auto_hide_time :
			overlay_console_normal_auto_hide_time);
  if (hide_time) {
    hide_time += timer_read();
    if (!hide_time)
      ++hide_time;
  }
  if (!overlay_window_is_shown(&console_window) || console_auto_hide)
    console_auto_hide = hide_time;
  overlay_window_set_shown(&console_window, true);
}

void overlay_console_toggle(void)
{
  if (!overlay_window_is_shown(&console_window) &&
      console_window.current_w && console_window.current_h)
    overlay_window_set_shown(&console_window, true);
  else
    overlay_window_set_shown(&console_window, false);
  console_auto_hide = 0;
}

static uint16_t overlay_window_init(struct overlay_window *ow, uint16_t base)
{
  ow->base = base;
  ow->lineoffs = ow->max_w*2;
  base += ow->max_h*ow->lineoffs;
  ow->current_w = 0;
  ow->current_h = 0;
  ow->cursor_y = 1;
  ow->cursor_x = 1;
  REGS_OVERLAY.window[ow->window_id].y0 = 0;
  REGS_OVERLAY.window[ow->window_id].x0 = 0;
  REGS_OVERLAY.window[ow->window_id].y1 = 0;
  REGS_OVERLAY.window[ow->window_id].x1 = 0;
  REGS_OVERLAY.window[ow->window_id].base = ow->base;
  REGS_OVERLAY.window[ow->window_id].lineoffs = ow->lineoffs;
  overlay_window_resize(ow, ow->min_w, ow->min_h);
  return base;
}

void overlay_task(void)
{
  if (console_auto_hide && ((int32_t)(console_auto_hide - timer_read())) < 0) {
    console_auto_hide = 0;
    overlay_window_set_shown(&console_window, false);
  }
}

void overlay_init(void)
{
  REGS_OVERLAY.control = 0;
  REGS_OVERLAY.xadj = 55;
  REGS_OVERLAY.yadj = 65;

  memcpy(OVERLAY, font_8x16, sizeof(font_8x16));

  uint16_t base = 0x1000;
  base = overlay_window_init(&console_window, base);
  base = overlay_window_init(&menu_window, base);
}
