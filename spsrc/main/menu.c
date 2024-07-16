#include "global.h"
#include "overlay.h"
#include "menu.h"
#include "keyboard.h"
#include "reset.h"

struct menu_page {
  const char * const * entries;
  void (*select_func)(unsigned entry);
  struct menu_page *parent;
};


static const char * const main_menu_entries[] = {
  "&Main menu",
  "=",
  "Load RPK",
  "-",
  "Reset and exit",
  "Exit",
  NULL
};

static void main_menu_select(unsigned entry);

static const struct menu_page main_menu = {
  main_menu_entries,
  main_menu_select,
  NULL
};

static const struct menu_page *current_menu = NULL;

static void main_menu_select(unsigned entry)
{
  switch(entry) {
  case 5:
    reset_set_other(true);
    reset_set_other(false);
    /* FALLTHRU */
  case 6:
    menu_close();
    break;
  }
}

static void menu_move(struct overlay_window *ow, const char * const * items,
		      int dir)
{
  int y = ow->cursor_y;
  for (;;) {
    y += dir;
    if (y < 1 || !items[y-1])
      return;
    if (items[y-1][0] && items[y-1][1] && items[y-1][0] != '&')
      break;
  }
  if (ow->cursor_y)
    overlay_window_invert_line(ow, ow->cursor_y);
  overlay_window_invert_line(ow, ow->cursor_y = y);
}

static void menu_draw(struct overlay_window *ow, const char * const * items)
{
  unsigned w = ow->min_w, h = 2;
  const char *p;
  for (const char * const * i = items; p = *i; i++) {
    h ++;
    if (*p == '&')
      ++p;
    unsigned l = strlen(p);
    if (l > w)
      w = l;
  }
  overlay_window_resize(ow, w, h);
  ow->cursor_y = 1;
  for (const char * const * i = items; p = *i; i++) {
    ow->cursor_x = 1;
    if (ow->cursor_y >= ow->current_h-1)
      break;
    if (*p == '&') {
      ow->text_color = WINDOW_COLOR(11, 4);
      ++p;
      unsigned l = strlen(p);
      if (l+2 < ow->current_w)
	ow->cursor_x += (ow->current_w-2-l) >> 1;
    } else
      ow->text_color = WINDOW_COLOR(15, 4);
    const char *pattern = NULL;
    if (p[0] && !p[1])
      switch(p[0]) {
      case '=':
	pattern = "\x90\x80\x93";
	p++;
	break;
      case '-':
	pattern = "\x8f\x10\x92";
	/* FALLTHRU */
      case ' ':
	p ++;
	break;
      }
    overlay_window_clear_line(ow, ow->cursor_y, pattern);
    while (*p && ow->cursor_x+1 < ow->current_w) {
      if (ow->cursor_x+2 == ow->current_w && p[1]) {
	overlay_window_putchar(ow, 0xf);
	break;
      }
      overlay_window_putchar(ow, *p++);
    }
    ow->cursor_y++;
  }
  ow->cursor_x = 1;
  while (ow->cursor_y+1 < ow->current_h)
    overlay_window_clear_line(ow, ow->cursor_y++, NULL);
  ow->cursor_y = 0;
  menu_move(ow, items, 1);
}

static void menu_set(const struct menu_page *page)
{
  current_menu = page;
  menu_draw(&menu_window, page->entries);
}

void menu_open(void)
{
  if (current_menu)
    return;
  keyboard_block();
  menu_set(&main_menu);
  overlay_window_set_shown(&menu_window, true);
}

void menu_close(void)
{
  if (!current_menu)
    return;
  if (current_menu->parent)
    menu_set(current_menu->parent);
  else {
    current_menu = NULL;
    overlay_window_set_shown(&menu_window, false);
    keyboard_unblock();
  }
}

void menu_key(char key)
{
  if (key == '\x1b')
    menu_close();
  else if (current_menu) {
    switch (key) {
    case '\x04':
      menu_move(&menu_window, current_menu->entries, -1);
      break;
    case '\x05':
      menu_move(&menu_window, current_menu->entries, 1);
      break;
    case '\n':
      if (current_menu->select_func)
	(*current_menu->select_func)(menu_window.cursor_y);
      break;
    }
  }
}
