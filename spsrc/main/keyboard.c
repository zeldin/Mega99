#include "global.h"
#include "keyboard.h"
#include "regs.h"
#include "overlay.h"
#include "menu.h"
#include "tikeys.h"

#define SHIFT_STATE_CTRL  0x800u
#define SHIFT_STATE_FCTN  0x400u
#define SHIFT_STATE_ALPHA 0x200u
#define SHIFT_STATE_SHIFT 0x100u

#define KEY_RELEASE       0x80u

#define KEYCODE_MASK      0x7fu
#define KEYBOARD_MODEL(x) (((x)>>12)&7u)

#define PSEUDO_FCTN  0x80u
#define PSEUDO_SHIFT 0x40u

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
  [0x41] = '\t',   // TAB
  [0x3F] = '\x1b', // RUN/STOP
  [0x47] = '\x1b', // Escape
  [0x39] = '\x1e', // Enter menu
  [0x43] = '\x1f', // Hide/reveal console

};

static const char keymap_mk1_pseudo[0x80] = {

  [0x38] = TIKEY_1,
  [0x3B] = TIKEY_2,
  [0x08] = TIKEY_3,
  [0x0B] = TIKEY_4,
  [0x10] = TIKEY_5,
  [0x13] = TIKEY_6,
  [0x18] = TIKEY_7,
  [0x1B] = TIKEY_8,
  [0x20] = TIKEY_9,
  [0x23] = TIKEY_0,
  [0x28] = (TIKEY_Equals + 48) | PSEUDO_SHIFT,
  [0x2B] = TIKEY_Slash | PSEUDO_SHIFT,
  [0x30] = TIKEY_Z | PSEUDO_FCTN,
  [0x33] = TIKEY_9 | PSEUDO_FCTN,
  [0x4C] = TIKEY_1 | PSEUDO_FCTN,

  [0x3E] = TIKEY_Q,
  [0x09] = TIKEY_W,
  [0x0E] = TIKEY_E,
  [0x11] = TIKEY_R,
  [0x16] = TIKEY_T,
  [0x19] = TIKEY_Y,
  [0x1E] = TIKEY_U,
  [0x21] = TIKEY_I,
  [0x26] = TIKEY_O,
  [0x29] = TIKEY_P,
  [0x2E] = TIKEY_2 | PSEUDO_SHIFT,
  [0x31] = TIKEY_8 | PSEUDO_SHIFT,
  [0x36] = TIKEY_6 | PSEUDO_SHIFT,

  [0x0A] = TIKEY_A,
  [0x0D] = TIKEY_S,
  [0x12] = TIKEY_D,
  [0x15] = TIKEY_F,
  [0x1A] = TIKEY_G,
  [0x1D] = TIKEY_H,
  [0x22] = TIKEY_J,
  [0x25] = TIKEY_K,
  [0x2A] = TIKEY_L,
  [0x2D] = TIKEY_Semic | PSEUDO_SHIFT,
  [0x32] = TIKEY_Semic,
  [0x35] = TIKEY_Equals + 48,
  [0x4D] = TIKEY_Enter,

  [0x0C] = TIKEY_Z,
  [0x17] = TIKEY_X,
  [0x14] = TIKEY_C,
  [0x1F] = TIKEY_V,
  [0x1C] = TIKEY_B,
  [0x27] = TIKEY_N,
  [0x24] = TIKEY_M,
  [0x2F] = TIKEY_Comma,
  [0x2C] = TIKEY_Period,
  [0x37] = TIKEY_Slash,

  [0x3C] = TIKEY_Space,

};

static const char keymap_mk1_pseudo_shift[0x80] = {

  [0x38] = TIKEY_1 | PSEUDO_SHIFT,
  [0x3B] = TIKEY_P | PSEUDO_FCTN,
  [0x08] = TIKEY_3 | PSEUDO_SHIFT,
  [0x0B] = TIKEY_4 | PSEUDO_SHIFT,
  [0x10] = TIKEY_5 | PSEUDO_SHIFT,
  [0x13] = TIKEY_7 | PSEUDO_SHIFT,
  [0x18] = TIKEY_O | PSEUDO_FCTN,
  [0x1B] = TIKEY_9 | PSEUDO_SHIFT,
  [0x20] = TIKEY_0 | PSEUDO_SHIFT,
  [0x23] = TIKEY_0,
  [0x28] = (TIKEY_Equals + 48) | PSEUDO_SHIFT,
  [0x2B] = TIKEY_Slash | PSEUDO_SHIFT,
  [0x30] = TIKEY_Z | PSEUDO_FCTN,
  [0x33] = TIKEY_3 | PSEUDO_FCTN,
  [0x4C] = TIKEY_2 | PSEUDO_FCTN,

  [0x3E] = TIKEY_Q | PSEUDO_SHIFT,
  [0x09] = TIKEY_W | PSEUDO_SHIFT,
  [0x0E] = TIKEY_E | PSEUDO_SHIFT,
  [0x11] = TIKEY_R | PSEUDO_SHIFT,
  [0x16] = TIKEY_T | PSEUDO_SHIFT,
  [0x19] = TIKEY_Y | PSEUDO_SHIFT,
  [0x1E] = TIKEY_U | PSEUDO_SHIFT,
  [0x21] = TIKEY_I | PSEUDO_SHIFT,
  [0x26] = TIKEY_O | PSEUDO_SHIFT,
  [0x29] = TIKEY_P | PSEUDO_SHIFT,
  [0x2E] = TIKEY_2 | PSEUDO_SHIFT,
  [0x31] = TIKEY_8 | PSEUDO_SHIFT,
  [0x36] = TIKEY_6 | PSEUDO_SHIFT,

  [0x0A] = TIKEY_A | PSEUDO_SHIFT,
  [0x0D] = TIKEY_S | PSEUDO_SHIFT,
  [0x12] = TIKEY_D | PSEUDO_SHIFT,
  [0x15] = TIKEY_F | PSEUDO_SHIFT,
  [0x1A] = TIKEY_G | PSEUDO_SHIFT,
  [0x1D] = TIKEY_H | PSEUDO_SHIFT,
  [0x22] = TIKEY_J | PSEUDO_SHIFT,
  [0x25] = TIKEY_K | PSEUDO_SHIFT,
  [0x2A] = TIKEY_L | PSEUDO_SHIFT,
  [0x2D] = TIKEY_R | PSEUDO_FCTN,
  [0x32] = TIKEY_T | PSEUDO_FCTN,
  [0x35] = TIKEY_Equals + 48,
  [0x4D] = TIKEY_Enter | PSEUDO_SHIFT,

  [0x0C] = TIKEY_Z | PSEUDO_SHIFT,
  [0x17] = TIKEY_X | PSEUDO_SHIFT,
  [0x14] = TIKEY_C | PSEUDO_SHIFT,
  [0x1F] = TIKEY_V | PSEUDO_SHIFT,
  [0x1C] = TIKEY_B | PSEUDO_SHIFT,
  [0x27] = TIKEY_N | PSEUDO_SHIFT,
  [0x24] = TIKEY_M | PSEUDO_SHIFT,
  [0x2F] = TIKEY_Comma | PSEUDO_SHIFT,
  [0x2C] = TIKEY_Period | PSEUDO_SHIFT,
  [0x37] = TIKEY_I | PSEUDO_FCTN,

  [0x3C] = TIKEY_Space | PSEUDO_SHIFT,

};

static const char keymap_mk1_pseudo_fctn[0x80] = {

  [0x39] = TIKEY_C | PSEUDO_FCTN,
  [0x38] = TIKEY_1 | PSEUDO_FCTN,
  [0x3B] = TIKEY_2 | PSEUDO_FCTN,
  [0x08] = TIKEY_3 | PSEUDO_FCTN,
  [0x0B] = TIKEY_4 | PSEUDO_FCTN,
  [0x10] = TIKEY_5 | PSEUDO_FCTN,
  [0x13] = TIKEY_6 | PSEUDO_FCTN,
  [0x18] = TIKEY_7 | PSEUDO_FCTN,
  [0x1B] = TIKEY_8 | PSEUDO_FCTN,
  [0x20] = TIKEY_9 | PSEUDO_FCTN,
  [0x23] = TIKEY_0 | PSEUDO_FCTN,
  [0x28] = (TIKEY_Equals + 48) | PSEUDO_FCTN,

  [0x3E] = TIKEY_Q | PSEUDO_FCTN,
  [0x09] = TIKEY_W | PSEUDO_FCTN,
  [0x0E] = TIKEY_E | PSEUDO_FCTN,
  [0x11] = TIKEY_R | PSEUDO_FCTN,
  [0x16] = TIKEY_T | PSEUDO_FCTN,
  [0x19] = TIKEY_Y | PSEUDO_FCTN,
  [0x1E] = TIKEY_U | PSEUDO_FCTN,
  [0x21] = TIKEY_I | PSEUDO_FCTN,
  [0x26] = TIKEY_O | PSEUDO_FCTN,
  [0x29] = TIKEY_P | PSEUDO_FCTN,

  [0x0A] = TIKEY_A | PSEUDO_FCTN,
  [0x0D] = TIKEY_S | PSEUDO_FCTN,
  [0x12] = TIKEY_D | PSEUDO_FCTN,
  [0x15] = TIKEY_F | PSEUDO_FCTN,
  [0x1A] = TIKEY_G | PSEUDO_FCTN,
  [0x1D] = TIKEY_H | PSEUDO_FCTN,
  [0x22] = TIKEY_J | PSEUDO_FCTN,
  [0x25] = TIKEY_K | PSEUDO_FCTN,
  [0x2A] = TIKEY_L | PSEUDO_FCTN,
  [0x2D] = TIKEY_F | PSEUDO_FCTN,
  [0x32] = TIKEY_G | PSEUDO_FCTN,
  [0x35] = TIKEY_U | PSEUDO_FCTN,
  [0x4D] = TIKEY_Enter | PSEUDO_FCTN,

  [0x0C] = TIKEY_Z | PSEUDO_FCTN,
  [0x17] = TIKEY_X | PSEUDO_FCTN,
  [0x14] = TIKEY_C | PSEUDO_FCTN,
  [0x1F] = TIKEY_V | PSEUDO_FCTN,
  [0x1C] = TIKEY_B | PSEUDO_FCTN,
  [0x27] = TIKEY_N | PSEUDO_FCTN,
  [0x24] = TIKEY_M | PSEUDO_FCTN,
  [0x2F] = TIKEY_W | PSEUDO_FCTN,
  [0x2C] = TIKEY_A | PSEUDO_FCTN,
  [0x37] = TIKEY_Z | PSEUDO_FCTN,

  [0x3C] = TIKEY_Space | PSEUDO_FCTN,

};

static const char keymap_ti[48] = {

  [TIKEY_1] = '1',
  [TIKEY_2] = '2',
  [TIKEY_3] = '3',
  [TIKEY_4] = '4',
  [TIKEY_5] = '5',
  [TIKEY_6] = '6',
  [TIKEY_7] = '7',
  [TIKEY_8] = '8',
  [TIKEY_9] = '9',
  [TIKEY_0] = '0',
  [TIKEY_Equals] = '=',

  [TIKEY_Q] = 'Q',
  [TIKEY_W] = 'W',
  [TIKEY_E] = 'E',
  [TIKEY_R] = 'R',
  [TIKEY_T] = 'T',
  [TIKEY_Y] = 'Y',
  [TIKEY_U] = 'U',
  [TIKEY_I] = 'I',
  [TIKEY_O] = 'O',
  [TIKEY_P] = 'P',
  [TIKEY_Slash] = '/',

  [TIKEY_A] = 'A',
  [TIKEY_S] = 'S',
  [TIKEY_D] = 'D',
  [TIKEY_F] = 'F',
  [TIKEY_G] = 'G',
  [TIKEY_H] = 'H',
  [TIKEY_J] = 'J',
  [TIKEY_K] = 'K',
  [TIKEY_L] = 'L',
  [TIKEY_Semic] = ';',
  [TIKEY_Enter] = '\n',

  [TIKEY_Z] = 'Z',
  [TIKEY_X] = 'X',
  [TIKEY_C] = 'C',
  [TIKEY_V] = 'V',
  [TIKEY_B] = 'B',
  [TIKEY_N] = 'N',
  [TIKEY_M] = 'M',
  [TIKEY_Comma] = ',',
  [TIKEY_Period] = '.',

  [TIKEY_Space] = ' ',

};

static uint8_t pseudokey_active; /* Release code for current pseudokey */
static uint8_t pseudokey_mode; /* 0 = off, 1 = on, 2 = blocked */

void keyboard_block(void)
{
  if (pseudokey_mode)
    pseudokey_mode = 2;
  else
    REGS_KEYBOARD.block = 1;
}

void keyboard_unblock(void)
{
  if (pseudokey_mode)
    pseudokey_mode = 1;
  else
    REGS_KEYBOARD.block = 0;
}

static void toggle_pseudokeys(void)
{
  if (pseudokey_mode) {
    if (pseudokey_mode == 1)
      REGS_KEYBOARD.block = 0;
    pseudokey_mode = 0;
    printf("Pseudokeys disabled\n");
  } else {
    if (REGS_KEYBOARD.block)
      pseudokey_mode = 2;
    else
      pseudokey_mode = 1;
    REGS_KEYBOARD.block = 1;
    printf("Pseudokeys enabled\n");
  }
}

static char apply_shiftstate(char key, uint16_t keycode)
{
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
	return 0;
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
	return 0;
    } else if ((keycode & SHIFT_STATE_SHIFT)) {
      static const char shift_chars['='-','+1] = "<->-)!@#$%^&*(::<+";
      if (key >= ',' && key <= '=')
	key = shift_chars[key-','];
    }
  }
  return key;
}

static char do_pseudokey(char key, uint16_t keycode, bool send)
{
  uint16_t key_high = 0;
  uint32_t key_low = 0;
  unsigned remapped = 0;
  if ((keycode & SHIFT_STATE_CTRL))
    key_high |= TIMOD_CTRL;
  if (key >= 4 && key <= 7) {
    static const uint8_t arrow_keys[] = { TIKEY_E, TIKEY_X, TIKEY_D, TIKEY_S };
    key_high |= TIMOD_FCTN;
    remapped = arrow_keys[key-4];
  } else {
    const char *keymap = NULL;
    if (KEYBOARD_MODEL(keycode) == 1) {
      if ((keycode & SHIFT_STATE_FCTN))
	keymap = keymap_mk1_pseudo_fctn;
      else if ((keycode & SHIFT_STATE_SHIFT))
	keymap = keymap_mk1_pseudo_shift;
      else
	keymap = keymap_mk1_pseudo;
    }
    if (!keymap)
      return key;
    uint8_t k = keymap[keycode & KEYCODE_MASK];
    remapped = k & 0x3f;
    if (k & 0x80)
      key_high |= TIMOD_FCTN;
    if (k & 0x40)
      key_high |= TIMOD_SHIFT;
  }
  if (!remapped)
    return key;
  else if (remapped >= 48)
    remapped -= 48;
  if (remapped < 16)
    key_high |= (0x8000u >> remapped);
  else
    key_low |= (0x80000000u >> (remapped-16));
  if (send) {
    REGS_KEYBOARD.synth_key_low = key_low;
    REGS_KEYBOARD.synth_key_high = key_high;
    pseudokey_active = keycode | KEY_RELEASE;
  }
  keycode &= ~(SHIFT_STATE_FCTN | SHIFT_STATE_SHIFT);
  if ((key_high & TIMOD_FCTN))
    keycode |= SHIFT_STATE_FCTN;
  if ((key_high & TIMOD_SHIFT))
    keycode |= SHIFT_STATE_SHIFT;
  char newkey = apply_shiftstate(keymap_ti[remapped], keycode);
  return (newkey? newkey : key);
}

void keyboard_task(void)
{
  uint16_t keycode = REGS_KEYBOARD.keycode;

  if (!(keycode & 0x8000u))
    return; // No keypress

  if (pseudokey_active && pseudokey_active == (keycode & 0xff)) {
    REGS_KEYBOARD.synth_key_low = 0;
    REGS_KEYBOARD.synth_key_high = 0;
    pseudokey_active = 0;
  }

  if ((keycode & KEY_RELEASE))
    return;

  const char *keymap;
  switch (KEYBOARD_MODEL(keycode)) {
  case 0: keymap = keymap_ps2; break;
  case 1: keymap = keymap_mk1; break;
  default: return;
  }

  char key = keymap[keycode & KEYCODE_MASK];

  if (key == '\t') {
    toggle_pseudokeys();
    return;
  }

  if (key)
    key = apply_shiftstate(key, keycode);

  if (pseudokey_mode == 1 ||
      (key >= 4 && key <= 7 && !REGS_KEYBOARD.block))
    key = do_pseudokey(key, keycode, true);
  else if (pseudokey_mode)
    key = do_pseudokey(key, keycode, false);

  if (!key)
    return;

  if ((keycode & SHIFT_STATE_CTRL))
    return; // No handling of control characters, currently

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
