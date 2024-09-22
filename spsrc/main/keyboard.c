#include "global.h"
#include "keyboard.h"
#include "regs.h"
#include "overlay.h"
#include "menu.h"

#define SHIFT_STATE_CTRL  0x800u
#define SHIFT_STATE_FCTN  0x400u
#define SHIFT_STATE_ALPHA 0x200u
#define SHIFT_STATE_SHIFT 0x100u

#define KEYCODE_MASK      0x7fu
#define KEYBOARD_MODEL(x) (((x)>>12)&7u)

static const char keymap_ps2[0x80] = {

  [0x16] = '1',
  [0x1E] = '2',
  [0x26] = '3',
  [0x25] = '4',
  [0x2E] = '5',
  [0x36] = '6',
  [0x3D] = '7',
  [0x3E] = '8',
  [0x46] = '9',
  [0x45] = '0',
  [0x4E] = '=',

  [0x15] = 'Q',
  [0x1D] = 'W',
  [0x24] = 'E',
  [0x2D] = 'R',
  [0x2C] = 'T',
  [0x35] = 'Y',
  [0x3C] = 'U',
  [0x43] = 'I',
  [0x44] = 'O',
  [0x4D] = 'P',
  [0x54] = '/',

  [0x1C] = 'A',
  [0x1B] = 'S',
  [0x23] = 'D',
  [0x2B] = 'F',
  [0x34] = 'G',
  [0x33] = 'H',
  [0x3B] = 'J',
  [0x42] = 'K',
  [0x4B] = 'L',
  [0x4C] = ';',
  [0x5A] = '\n',

  [0x1A] = 'Z',
  [0x22] = 'X',
  [0x21] = 'C',
  [0x2A] = 'V',
  [0x32] = 'B',
  [0x31] = 'N',
  [0x3A] = 'M',
  [0x41] = ',',
  [0x49] = '.',

  [0x29] = ' ',

  [0x75] = '\x04', // Arrow up
  [0x72] = '\x05', // Arrow down
  [0x74] = '\x06', // Arrow right
  [0x6B] = '\x07', // Arrow left
  [0x66] = '\b',   // Backspace
  [0x76] = '\x1b', // Escape
  [0x0E] = '\x1e', // Enter menu
  [0x7C] = '\x1f', // Hide/reveal console

};

static const char keymap_mk1[0x80] = {

  [0x38] = '1',
  [0x3B] = '2',
  [0x08] = '3',
  [0x0B] = '4',
  [0x10] = '5',
  [0x13] = '6',
  [0x18] = '7',
  [0x1B] = '8',
  [0x20] = '9',
  [0x23] = '0',
  [0x28] = '=',

  [0x3E] = 'Q',
  [0x09] = 'W',
  [0x0E] = 'E',
  [0x11] = 'R',
  [0x16] = 'T',
  [0x19] = 'Y',
  [0x1E] = 'U',
  [0x21] = 'I',
  [0x26] = 'O',
  [0x29] = 'P',
  [0x2E] = '/',

  [0x0A] = 'A',
  [0x0D] = 'S',
  [0x12] = 'D',
  [0x15] = 'F',
  [0x1A] = 'G',
  [0x1D] = 'H',
  [0x22] = 'J',
  [0x25] = 'K',
  [0x2A] = 'L',
  [0x2D] = ';',
  [0x4D] = '\n',

  [0x0C] = 'Z',
  [0x17] = 'X',
  [0x14] = 'C',
  [0x1F] = 'V',
  [0x1C] = 'B',
  [0x27] = 'N',
  [0x24] = 'M',
  [0x2F] = ',',
  [0x2C] = '.',

  [0x3C] = ' ',

  [0x49] = '\x04', // Arrow up
  [0x07] = '\x05', // Arrow down
  [0x02] = '\x06', // Arrow right
  [0x4A] = '\x07', // Arrow left
  [0x4C] = '\b',   // Backspace
  [0x3F] = '\x1b', // RUN/STOP
  [0x47] = '\x1b', // Escape
  [0x39] = '\x1e', // Enter menu
  [0x43] = '\x1f', // Hide/reveal console

};

void keyboard_block(void)
{
  REGS_KEYBOARD.block = 1;
}

void keyboard_unblock(void)
{
  REGS_KEYBOARD.block = 0;
}

void keyboard_task(void)
{
  uint16_t keycode = REGS_KEYBOARD.keycode;
  if (!(keycode & 0x8000u))
    return; // No keypress

  if ((keycode & SHIFT_STATE_CTRL))
    return; // No handling of control characters, currently

  const char *keymap;
  switch (KEYBOARD_MODEL(keycode)) {
  case 0: keymap = keymap_ps2; break;
  case 1: keymap = keymap_mk1; break;
  default: return;
  }

  char key = keymap[keycode & KEYCODE_MASK];
  if (!key)
    return;

  if (key >= 'A' && key <= 'Z') {
    if ((keycode & SHIFT_STATE_FCTN)) {
      static const char fctn_chars['Z'-'A'+1] = {
	['W'-'A'] = '~', ['E'-'A'] = '\x04', ['R'-'A'] = '[', ['T'-'A'] = ']',
	['U'-'A'] = '_', ['I'-'A'] = '?', ['O'-'A'] = '\'', ['P'-'A'] = '"',
	['A'-'A'] = '|', ['S'-'A'] = '\x07', ['D'-'A'] = '\x06',
	['F'-'A'] = '{', ['G'-'A'] = '}',
	['Z'-'A'] = '\\', ['X'-'A'] = '\x05', ['C'-'A'] = '`'
      };
      if (!(key = fctn_chars[key-'A']))
	return;
    } else if (!(keycode & (SHIFT_STATE_SHIFT | SHIFT_STATE_ALPHA)))
      key |= 0x20; // No shift / alpha lock -> lowercase
  } else {
    if ((keycode & SHIFT_STATE_FCTN)) {
      // Only support FCTN-1 == backspace and FCTN-9 == Escape
      if (key == '1')
	key = '\b';
      else if (key == '9')
	key = '\x1b';
      else
	return;
    } else if ((keycode & SHIFT_STATE_SHIFT)) {
      static const char shift_chars['='-','+1] = "<->-)!@#$%^&*(::<+";
      if (key >= ',' && key <= '=')
	key = shift_chars[key-','];
    }
  }

  if (key == '\x1f')
    overlay_console_toggle();
  else if (key == '\x1e')
    menu_open();
  else
    menu_key(key);
}

void keyboard_flush(void)
{
  uint16_t keycode;
  do
    keycode = REGS_KEYBOARD.keycode;
  while ((keycode & 0x8000u));
}
