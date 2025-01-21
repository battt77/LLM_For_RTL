#include "include/include.h"
#include <SDL2/SDL.h>

extern void init_screen();
void init_i8042();

void send_key(uint8_t, bool);
void vga_update_screen();

void device_update() {
  static uint64_t last = 0;
  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
  uint64_t cur = now.tv_sec * 1000000 + now.tv_nsec / 1000;
  if (cur - last < 1000000)
  {
      return;
  }
  last = cur;

  vga_update_screen();


  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        npc_state.state = NPC_QUIT;
        break;
#ifdef CONFIG_HAS_KEYBOARD
      // If a key was pressed
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
        uint8_t k = event.key.keysym.scancode;
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
        send_key(k, is_keydown);
        break;
      }
#endif
      default: break;
    }
  }

}

// void sdl_clear_event_queue() {
//   SDL_Event event;
//   while (SDL_PollEvent(&event));
// }

void init_device() {
  //IFDEF(CONFIG_TARGET_AM, ioe_init());
 
    init_screen();
    init_i8042();


}
