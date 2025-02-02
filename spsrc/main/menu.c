#include "global.h"
#include "overlay.h"
#include "menu.h"
#include "keyboard.h"
#include "reset.h"
#include "fatfs.h"
#include "sdcard.h"
#include "rpk.h"
#include "fdc.h"
#include "tape.h"
#include "strerr.h"
#include "regs.h"
#include "mem.h"

#define MAX_FILESELECTOR_FILES 1000
#define MAX_FILESELECTOR_NAMELEN 40
#define MAX_FILESELECTOR_ENTRIES 20 /* Matches height of menu */

#define FILETYPE_FILE  0x10
#define FILETYPE_DIR   0x11
#define FILETYPE_LABEL 0x12
#define MINOR_TITLE    0x13

#define MT "\x13"

static const uint16_t menu_altcolor[] = {
  WINDOW_COLOR(15, 4),
  WINDOW_COLOR(5, 4),
  WINDOW_COLOR(13, 4),
  WINDOW_COLOR(14, 4),
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
  "Mount DSK1 disk image",
  "Mount DSK2 disk image",
  "Mount DSK3 disk image",
  "-",
  "Open CS1 input file",
  "Save CS1 recording",
  "Save CS2 recording",
  "-",
  "Load Mini Memory RAM",
  "Save Mini Memory RAM",
  "-",
  "Settings",
  "-",
  "Reset and exit",
  "Exit",
  NULL
};

static char settings_menu_entry_32k[] = "\x0c Enabled  \x0d Disabled";
static char settings_menu_entry_fdc[] = "\x0c Enabled  \x0d Disabled";
static char settings_menu_entry_vsp[] = "\x0c Enabled  \x0d Disabled";
static char settings_menu_entry_scratchpad[] = "\x0c 256 bytes  \x0d 1K";
static char settings_menu_entry_joysticks[] = "\x0c Normal  \x0d Swapped";
static char settings_menu_entry_tipi[] = "\x0c >1200  \x0d >1000  \x0d Disabled";

static const char * const settings_menu_entries[] = {
  "&Settings",
  "=",
  MT "32K RAM expansion",
  settings_menu_entry_32k,
  MT "Floppy controller",
  settings_menu_entry_fdc,
  MT "Speech synthesizer",
  settings_menu_entry_vsp,
  MT "Scratchpad RAM size",
  settings_menu_entry_scratchpad,
  MT "Joysticks",
  settings_menu_entry_joysticks,
  MT "TIPI",
  settings_menu_entry_tipi,
  "-",
  "Back to main menu",
  NULL
};

static const char * fileselector_menu_entries[MAX_FILESELECTOR_ENTRIES];
static char fileselector_menu_names[MAX_FILESELECTOR_FILES][MAX_FILESELECTOR_NAMELEN+1];
static char textinput_buffer[256];

static fatfs_filehandle_t saved_rpk_dir, saved_dsk_dir,
  saved_tap_dir, saved_mm_dir, *fileselector_saved_dir = NULL;

static void menu_set(const struct menu_page *page);
static void menu_redraw(void);
static void main_menu_select(unsigned entry);
static void settings_menu_select(unsigned entry);
static void settings_menu_update(void);
static void fileselector_menu_select(unsigned entry);
static void fileselector_menu_refill(void);
static void menu_open_fileselector(const char *title,
				   void (*open_func)(fatfs_filehandle_t *fh,
						     const char *filename),
				   fatfs_filehandle_t *saved_dir);
static void menu_text_input(const char *title,
			    void (*input_func)(const char *data, unsigned len),
			    bool (*filter_func)(char key));

static const struct menu_page main_menu = {
  main_menu_entries,
  main_menu_select,
  NULL
};

static const struct menu_page settings_menu = {
  settings_menu_entries,
  settings_menu_select,
  &main_menu
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
static unsigned menu_dsk_number;
static void (*textinput_func)(const char *data, unsigned len) = NULL;
static bool (*textinput_filter)(char key) = NULL;
static unsigned textinput_cnt, textinput_offs;

static bool filename_filter(char key)
{
  switch (key) {
    /* Characters not allowed in VFAT filenames */
  case '*':
  case '"':
  case '/':
  case '\\':
  case '<':
  case '>':
  case ':':
  case '|':
  case '?':
    return false;
  }
  return true;
}

static void menu_open_func_rpk(fatfs_filehandle_t *fh, const char *filename)
{
  load_rpk_fh(filename, fh);
}

static void menu_open_func_disk(fatfs_filehandle_t *fh, const char *filename)
{
  fdc_mount(menu_dsk_number, fh);
}

static void menu_open_func_tape(fatfs_filehandle_t *fh, const char *filename)
{
  tape_start(fh);
}

static void menu_text_input_func_save_cs1(const char *data, unsigned len)
{
  tape_save(0, data);
}

static void menu_text_input_func_save_cs2(const char *data, unsigned len)
{
  tape_save(1, data);
}

static void menu_open_func_mm(fatfs_filehandle_t *fh, const char *filename)
{
  mm_load(filename, fh);
}

static void menu_text_input_func_save_mm(const char *data, unsigned len)
{
  mm_save(data);
}

static void main_menu_select(unsigned entry)
{
  switch(entry) {
  case 3:
    menu_open_fileselector("&Select RPK file to load", menu_open_func_rpk,
			   &saved_rpk_dir);
    break;
  case 5:
  case 6:
  case 7:
    menu_dsk_number = entry-5;
    menu_open_fileselector("&Select DSK file to open", menu_open_func_disk,
			   &saved_dsk_dir);
    break;
  case 9:
    menu_open_fileselector("&Select WAV or TAP file to open", menu_open_func_tape,
			   &saved_tap_dir);
    break;
  case 10:
    menu_text_input("&Enter filename for saving CS1 buffer",
		    menu_text_input_func_save_cs1, filename_filter);
    break;
  case 11:
    menu_text_input("&Enter filename for saving CS2 buffer",
		    menu_text_input_func_save_cs2, filename_filter);
    break;
  case 13:
    menu_open_fileselector("&Select Mini Memory RAM image to open",
			   menu_open_func_mm, &saved_mm_dir);
    break;
  case 14:
    menu_text_input("&Enter filename for saving MM RAM",
		    menu_text_input_func_save_mm, filename_filter);
    break;
  case 16:
    settings_menu_update();
    menu_set(&settings_menu);
    break;
  case 18:
    reset_set_other(true);
    reset_set_other(false);
    /* FALLTHRU */
  case 19:
    menu_close();
    break;
  }
}

static void settings_menu_select(unsigned entry)
{
  switch(entry) {
  case 4:
    REGS_MISC.enable ^= REGS_MISC_ENABLE_RAM32K;
    settings_menu_update();
    break;
  case 6:
    REGS_MISC.enable ^= REGS_MISC_ENABLE_FDC;
    settings_menu_update();
    break;
  case 8:
    REGS_MISC.enable ^= REGS_MISC_ENABLE_VSP;
    settings_menu_update();
    break;
  case 10:
    REGS_MISC.enable ^= REGS_MISC_ENABLE_1KSP;
    settings_menu_update();
    break;
  case 12:
    REGS_MISC.enable ^= REGS_MISC_ENABLE_JOYSWP;
    settings_menu_update();
    break;
  case 14:
    if (!(REGS_MISC.enable & REGS_MISC_ENABLE_TIPI))
      REGS_MISC.enable |=
	REGS_MISC_ENABLE_TIPI | (2u << REGS_MISC_ENABLE_TIPI_CRUADDR_SHIFT);
    else {
      REGS_MISC.enable &= ~REGS_MISC_ENABLE_TIPI;
      if ((REGS_MISC.enable & (2u << REGS_MISC_ENABLE_TIPI_CRUADDR_SHIFT)))
	REGS_MISC.enable ^=
	  REGS_MISC_ENABLE_TIPI | (2u << REGS_MISC_ENABLE_TIPI_CRUADDR_SHIFT);
    }
    settings_menu_update();
    break;
  case 16:
    menu_close();
    break;
  }
}

static void update_settings_line3(char *line, uint16_t first, uint16_t second)
{
  while (*line) {
    if (*line == 0xc || *line == 0xd) {
      *line = (first ? 0xc : 0xd);
      if (first)
	first = second = 0;
      else if (second) {
	first = second;
	second = 0;
      } else {
	second = 1;
	first = 0;
      }
    }
    line++;
  }
}

static void update_settings_line(char *line, uint16_t first)
{
  update_settings_line3(line, first, !first);
}

static void settings_menu_update(void)
{
  uint16_t enabled = REGS_MISC.enable;
  update_settings_line(settings_menu_entry_32k,
		       enabled & REGS_MISC_ENABLE_RAM32K);
  update_settings_line(settings_menu_entry_fdc,
		       enabled & REGS_MISC_ENABLE_FDC);
  update_settings_line(settings_menu_entry_vsp,
		       enabled & REGS_MISC_ENABLE_VSP);
  update_settings_line(settings_menu_entry_scratchpad,
		       (~enabled) & REGS_MISC_ENABLE_1KSP);
  update_settings_line(settings_menu_entry_joysticks,
		       (~enabled) & REGS_MISC_ENABLE_JOYSWP);
  if (!TIPIROM[0])
    strcpy(settings_menu_entry_tipi, MT "Unavailable (no DSR)");
  else
    update_settings_line3(settings_menu_entry_tipi,
			  enabled & (2u<<REGS_MISC_ENABLE_TIPI_CRUADDR_SHIFT),
			  enabled & REGS_MISC_ENABLE_TIPI);
  if (current_menu == &settings_menu)
    menu_redraw();
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

static void menu_textinput_draw(struct overlay_window *ow, const char * title)
{
  unsigned scmarker;
  overlay_window_resize(ow, 40, 5);
  ow->cursor_y = 1;
  while (ow->cursor_y < 3) {
    const char *p = (ow->cursor_y == 1? title : "-");
    ow->cursor_x = 1;
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
  ow->cursor_y = 3;
  ow->text_color = ow->background_color = WINDOW_COLOR(15, 4);
  overlay_window_clear_line(ow, 3, NULL);
  overlay_window_toggle_cursor(ow);
}

static void menu_textinput_redraw(struct overlay_window *ow)
{
  unsigned n = textinput_offs;
  ow->cursor_x = 1;
  while (n < textinput_cnt && ow->cursor_x < ow->current_w-1)
    overlay_window_putchar(ow, textinput_buffer[n++]);
  while (ow->cursor_x < ow->current_w-1)
    overlay_window_putchar(ow, ' ');
  overlay_window_update_line_border(ow, ow->cursor_y,
				    (textinput_offs? 0x0b : 0x81),
				    (n < textinput_cnt? 0x0a : 0x81));
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
	items[y-1][0] != '&' && items[y-1][0] != FILETYPE_LABEL &&
	items[y-1][0] != MINOR_TITLE)
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

static void menu_redraw(void)
{
  int y = menu_window.cursor_y;
  menu_draw(&menu_window, current_menu->entries, current_menu->scroll_control);
  menu_move(&menu_window, current_menu->entries, y, current_menu->scroll_control);
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
  if (fileselector_saved_dir)
    *fileselector_saved_dir = fileselector_dir;
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
						     const char *filename),
				   fatfs_filehandle_t *saved_dir)
{
  fileselector_open_func = open_func;
  fileselector_menu_entries[0] = title;
  fileselector_menu_entries[1] = "-";

  int r = -ECARDCHANGED;
  if (saved_dir != NULL) {
    fileselector_saved_dir = saved_dir;
    if (saved_dir->start_cluster) {
      fileselector_dir = *saved_dir;
      r = fileselector_menu_fill(false);
    }
  } else
    fileselector_saved_dir = NULL;
  if (r == -ECARDCHANGED)
    r = fileselector_menu_fill(true);
  if (r == -ENOCARD && sdcard_num_cards() > 1) {
    sdcard_set_card_number(sdcard_get_card_number()? 0 : 1);
    r = fileselector_menu_fill(true);
  }
  if (r < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
  } else {
    fileselector_menu.parent = current_menu;
    menu_set(&fileselector_menu);
  }
}

static void menu_text_input(const char *title,
			    void (*input_func)(const char *data, unsigned len),
			    bool (*filter_func)(char key))
{
  textinput_func = input_func;
  textinput_filter = filter_func;
  textinput_cnt = 0;
  textinput_offs = 0;
  menu_textinput_draw(&menu_window, title);
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
  if (textinput_func) {
    textinput_func = NULL;
    textinput_filter = NULL;
    menu_set(current_menu);
  } else if (current_menu->parent)
    menu_set(current_menu->parent);
  else {
    current_menu = NULL;
    overlay_window_set_shown(&menu_window, false);
    keyboard_unblock();
  }
}

static void menu_textinput_key(struct overlay_window *ow, char key)
{
  unsigned input_pos = textinput_offs + ow->cursor_x - 1;
  if (key < 32)
    switch(key) {
    case '\x06':
      if (input_pos < textinput_cnt) {
	overlay_window_toggle_cursor(ow);
	if (++ow->cursor_x >= ow->current_w-1) {
	  textinput_offs += 8;
	  menu_textinput_redraw(ow);
	  ow->cursor_x = ow->current_w-9;
	}
	overlay_window_toggle_cursor(ow);
      }
      break;
    case '\x07':
      if (input_pos > 0) {
	overlay_window_toggle_cursor(ow);
	if (!--ow->cursor_x) {
	  textinput_offs -= 8;
	  menu_textinput_redraw(ow);
	  ow->cursor_x = 8;
	}
	overlay_window_toggle_cursor(ow);
      }
      break;
    case '\b':
      if (input_pos > 0) {
	overlay_window_toggle_cursor(ow);
	unsigned p = --ow->cursor_x;
	if (!p) {
	  textinput_offs -= 8;
	  p = 8;
	}
	if (input_pos < textinput_cnt)
	  memmove(textinput_buffer+input_pos-1, textinput_buffer+input_pos,
		  textinput_cnt - input_pos);
	--textinput_cnt;
	menu_textinput_redraw(ow);
	ow->cursor_x = p;
	overlay_window_toggle_cursor(ow);
      }
      break;
    case '\n':
      while (textinput_cnt > 0 && textinput_buffer[textinput_cnt-1] == ' ')
	--textinput_cnt;
      textinput_buffer[textinput_cnt] = 0;
      textinput_func(textinput_buffer, textinput_cnt);
      menu_close();
    }
  else if (key >= 127 && key < 160)
    ;
  else if (textinput_filter && !textinput_filter(key))
    ;
  else if (textinput_cnt < sizeof(textinput_buffer)-1) {
    overlay_window_putchar(ow, key);
    if (input_pos < textinput_cnt++) {
      memmove(textinput_buffer+input_pos+1, textinput_buffer+input_pos,
	      textinput_cnt-input_pos-1);
      textinput_buffer[input_pos] = key;
      unsigned p = ow->cursor_x;
      if (p >= ow->current_w-1) {
	textinput_offs += 8;
	p = ow->current_w-9;
      }
      menu_textinput_redraw(ow);
      ow->cursor_x = p;
    } else {
      textinput_buffer[input_pos] = key;
      if (ow->cursor_x >= ow->current_w-1) {
	textinput_offs += 8;
	menu_textinput_redraw(ow);
	ow->cursor_x = ow->current_w-9;
      }
    }
    overlay_window_toggle_cursor(ow);
  }
}

void menu_key(char key)
{
  if (key == '\x1b')
    menu_close();
  else if (textinput_func)
    menu_textinput_key(&menu_window, key);
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
    case '.':
      if (current_menu == &fileselector_menu && sdcard_num_cards() > 1) {
	int r;
	sdcard_set_card_number(sdcard_get_card_number() ^ 1);
	r = fileselector_menu_fill(true);
	if (r < 0) {
	  fprintf(stderr, "%s\n", fatfs_strerror(-r));
	  menu_close();
	} else {
	  menu_set(&fileselector_menu);
	}
      }
      break;
    }
  }
}
