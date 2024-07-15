#include "global.h"
#include "keyboard.h"
#include "regs.h"
#include "overlay.h"

#define SHIFT_STATE_CTRL  0x800u
#define SHIFT_STATE_FCTN  0x400u
#define SHIFT_STATE_ALPHA 0x200u
#define SHIFT_STATE_SHIFT 0x100u

#define KEYCODE_MASK 0x7fu

#define KEYCODE_NUMSTAR 0x7cu

void keyboard_task(void)
{
  uint16_t keycode = REGS_KEYBOARD.keycode;
  if (keycode & 0x8000u) {
    if ((keycode & (SHIFT_STATE_SHIFT | KEYCODE_MASK)) ==
	(SHIFT_STATE_SHIFT | KEYCODE_NUMSTAR)) // SysRq
      overlay_console_toggle();
  }
}
