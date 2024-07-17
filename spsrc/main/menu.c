#include "global.h"
#include "overlay.h"
#include "menu.h"
#include "keyboard.h"
#include "reset.h"
#include "fatfs.h"
#include "rpk.h"
#include "strerr.h"

#define MAX_FILESELECTOR_FILES 1000
#define MAX_FILESELECTOR_NAMELEN 40
#define MAX_FILESELECTOR_ENTRIES 16 /* Matches height of menu */

#define FILETYPE_FILE  0x10
#define FILETYPE_DIR   0x11
#define FILETYPE_LABEL 0x12

static const uint16_t menu_altcolor[] = {
  WINDOW_COLOR(15, 4),
  WINDOW_COLOR(5, 4),
  WINDOW_COLOR(13, 4),
};

struct menu_scroll_control {
  void (*refill_func)(void);
  unsigned visible_adjust;
  unsigned top_entry;
  unsigned total_entries;
  unsigned remaining_entries;
};

struct menu_page {
  const char * const * entries;
  void (*select_func)(unsigned entry);
  const struct menu_page *parent;
  struct menu_scroll_control *scroll_control;
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

static const char * fileselector_menu_entries[MAX_FILESELECTOR_ENTRIES];
static char fileselector_menu_names[MAX_FILESELECTOR_FILES][MAX_FILESELECTOR_NAMELEN+1];

static void main_menu_select(unsigned entry);
static void fileselector_menu_select(unsigned entry);
static void fileselector_menu_refill(void);
static void menu_open_fileselector(const char *title,
				   void (*open_func)(fatfs_filehandle_t *fh,
						     const char *filename));

static const struct menu_page main_menu = {
  main_menu_entries,
  main_menu_select,
  NULL
};

static struct menu_scroll_control fileselector_scroll_control = {
  fileselector_menu_refill, 2
};

static struct menu_page fileselector_menu = {
  fileselector_menu_entries,
  fileselector_menu_select,
  NULL,
  &fileselector_scroll_control
};

static const struct menu_page *current_menu = NULL;
static fatfs_filehandle_t fileselector_dir, fileselector_file[MAX_FILESELECTOR_FILES];

static void (*fileselector_open_func)(fatfs_filehandle_t *fh, const char *filename);
static unsigned fileselector_cnt;

static void menu_open_func_rpk(fatfs_filehandle_t *fh, const char *filename)
{
  load_rpk_fh(filename, fh);
}

static void main_menu_select(unsigned entry)
{
  switch(entry) {
  case 3:
    menu_open_fileselector("&Select RPK file to load", menu_open_func_rpk);
    break;
  case 5:
    reset_set_other(true);
    reset_set_other(false);
    /* FALLTHRU */
  case 6:
    menu_close();
    break;
  }
}

static void menu_draw(struct overlay_window *ow, const char * const * items,
		      struct menu_scroll_control *sc)
{
  unsigned w = ow->min_w, h = 2;
  unsigned scmarker;
  const char *p;
  for (const char * const * i = items; p = *i; i++) {
    h ++;
    if (*p == '&' ||
	(*p >= 0x10 && *p < 0x10+sizeof(menu_altcolor)/sizeof(menu_altcolor[0])))
      ++p;
    unsigned l = strlen(p) + 2;
    if (l > w)
      w = l;
  }
  overlay_window_resize(ow, w, h);
  if (sc) {
    unsigned bot = ow->current_h - 2 + sc->top_entry;
    if (sc->total_entries > bot)
      sc->remaining_entries = sc->total_entries - bot;
    else
      sc->remaining_entries = 0;
    if (sc->top_entry + sc->remaining_entries == 0)
      sc = NULL;
    else
      scmarker = (ow->current_h - 5 - sc->visible_adjust) *
	sc->top_entry / (sc->top_entry + sc->remaining_entries);
  }
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
    if (*p >= 0x10 && *p < 0x10+sizeof(menu_altcolor)/sizeof(menu_altcolor[0]))
      ow->text_color = menu_altcolor[*p++ - 0x10];
    ow->background_color = ow->text_color;
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
    if (sc && !pattern && ow->cursor_y > sc->visible_adjust) {
      if (ow->cursor_y == ow->current_h - 2)
	pattern = "\x81\x20\x09";
      else if (ow->cursor_y == sc->visible_adjust + 1)
	pattern = "\x81\x20\x08";
      else if (!scmarker) {
	pattern = "\x81\x20\x0e";
	scmarker = ow->current_h;
      } else {
	pattern = "\x81\x20\x9d";
	--scmarker;
      }
    }
    overlay_window_clear_line(ow, ow->cursor_y, pattern);
    while (*p && ow->cursor_x+1 < ow->current_w) {
      if (ow->cursor_x+2 == ow->current_w && p[1]) {
	overlay_window_putchar(ow, 0xf);
	break;
      }
      char c = *p++;
      overlay_window_putchar(ow, (c == 0x1a? 0 : c));
    }
    ow->cursor_y++;
  }
  ow->cursor_x = 1;
  while (ow->cursor_y+1 < ow->current_h)
    overlay_window_clear_line(ow, ow->cursor_y++, NULL);
  ow->cursor_y = 0;
}

static void menu_move(struct overlay_window *ow, const char * const * items,
		      int dir, struct menu_scroll_control *sc)
{
  int y = ow->cursor_y;
  for (;;) {
    y += dir;
    if (y < 1 && sc && sc->top_entry > 0) {
      sc->top_entry--;
      sc->refill_func();
      menu_draw(ow, items, sc);
      dir = 1;
      y = 0;
      sc = NULL;
      continue;
    }
    if (y+1 >= ow->current_h && sc && sc->remaining_entries > 0) {
      sc->top_entry++;
      sc->refill_func();
      menu_draw(ow, items, sc);
      sc = NULL;
      y = ow->current_h-1;
      dir = -1;
      continue;
    }
    if (y < 1 || !items[y-1] || y+1 >= ow->current_h)
      return;
    if (items[y-1][0] && items[y-1][1] &&
	items[y-1][0] != '&' && items[y-1][0] != FILETYPE_LABEL)
      break;
  }
  if (ow->cursor_y)
    overlay_window_invert_line(ow, ow->cursor_y);
  overlay_window_invert_line(ow, ow->cursor_y = y);
}

static void menu_set(const struct menu_page *page)
{
  current_menu = page;
  menu_draw(&menu_window, page->entries, page->scroll_control);
  menu_move(&menu_window, page->entries, 1, page->scroll_control);
}

static void fileselector_menu_refill(void)
{
  unsigned entry = 2, pos = fileselector_scroll_control.top_entry;
  while (entry < MAX_FILESELECTOR_ENTRIES-1 && pos < fileselector_cnt)
    fileselector_menu_entries[entry++] = fileselector_menu_names[pos++];
  fileselector_menu_entries[entry] = NULL;
}

static int fileselector_menu_fill(bool root)
{
  int r;
  char *p;
  fileselector_cnt = 0;
  if (root &&
      (r = fatfs_open_rootdir(&fileselector_dir)) < 0)
    return r;
  while((r = fatfs_read_directory(&fileselector_dir, &fileselector_file[fileselector_cnt],
				  (p = fileselector_menu_names[fileselector_cnt])+1,
				  MAX_FILESELECTOR_NAMELEN)) > 0) {
    if ((r & 8))
      *p = FILETYPE_LABEL;
    else if ((r & 16)) {
      *p = FILETYPE_DIR;
      if (p[1] == '.' && p[2] == 0)
	continue;
    } else
      *p = FILETYPE_FILE;
    if (++fileselector_cnt >= MAX_FILESELECTOR_FILES)
      break;
  }
  fileselector_scroll_control.top_entry = 0;
  fileselector_scroll_control.total_entries = fileselector_cnt + 2;
  fileselector_menu_refill();
  return r;
}

static void fileselector_menu_select(unsigned entry)
{
  char typ = 0;
  if (entry >= 3) {
    entry -= 3;
    entry += fileselector_scroll_control.top_entry;
    if (entry < fileselector_cnt)
      typ = fileselector_menu_names[entry][0];
  }
  switch (typ) {
  case FILETYPE_DIR:
    fileselector_dir = fileselector_file[entry];
    int r = fileselector_menu_fill(!fileselector_dir.start_cluster);
    if (r < 0) {
      fprintf(stderr, "%s\n", fatfs_strerror(-r));
      menu_close();
    } else {
      menu_set(&fileselector_menu);
    }
    break;
  case FILETYPE_FILE:
    if (fileselector_open_func)
      (*fileselector_open_func)(&fileselector_file[entry],
				&fileselector_menu_names[entry][1]);
    /* FALLTHRU */
  default:
    menu_close();
    break;
  }
}

static void menu_open_fileselector(const char *title,
				   void (*open_func)(fatfs_filehandle_t *fh,
						     const char *filename))
{
  fileselector_open_func = open_func;
  fileselector_menu_entries[0] = title;
  fileselector_menu_entries[1] = "-";

  int r = fileselector_menu_fill(true);
  if (r < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
  } else {
    fileselector_menu.parent = current_menu;
    menu_set(&fileselector_menu);
  }
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
      menu_move(&menu_window, current_menu->entries,
		-1, current_menu->scroll_control);
      break;
    case '\x05':
      menu_move(&menu_window, current_menu->entries,
		1, current_menu->scroll_control);
      break;
    case '\n':
      if (current_menu->select_func)
	(*current_menu->select_func)(menu_window.cursor_y);
      break;
    }
  }
}
