#include <am.h>
#include "include/npc.h"

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  // kbd->keydown = 0;
  // kbd->keycode = AM_KEY_NONE;
  uint32_t scancode = inl(KBD_ADDR);
  kbd->keydown = scancode & KEYDOWN_MASK ? true : false;
  kbd->keycode = scancode & ~KEYDOWN_MASK;
}
