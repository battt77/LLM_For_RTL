#include "include/include.h"
#include <SDL2/SDL.h>
#include <assert.h>
#define KEYDOWN_MASK 0x8000



// Note that this is not the standard
#define NPC_KEYS(f) \
  f(ESCAPE) f(F1) f(F2) f(F3) f(F4) f(F5) f(F6) f(F7) f(F8) f(F9) f(F10) f(F11) f(F12) \
f(GRAVE) f(1) f(2) f(3) f(4) f(5) f(6) f(7) f(8) f(9) f(0) f(MINUS) f(EQUALS) f(BACKSPACE) \
f(TAB) f(Q) f(W) f(E) f(R) f(T) f(Y) f(U) f(I) f(O) f(P) f(LEFTBRACKET) f(RIGHTBRACKET) f(BACKSLASH) \
f(CAPSLOCK) f(A) f(S) f(D) f(F) f(G) f(H) f(J) f(K) f(L) f(SEMICOLON) f(APOSTROPHE) f(RETURN) \
f(LSHIFT) f(Z) f(X) f(C) f(V) f(B) f(N) f(M) f(COMMA) f(PERIOD) f(SLASH) f(RSHIFT) \
f(LCTRL) f(APPLICATION) f(LALT) f(SPACE) f(RALT) f(RCTRL) \
f(UP) f(DOWN) f(LEFT) f(RIGHT) f(INSERT) f(DELETE) f(HOME) f(END) f(PAGEUP) f(PAGEDOWN)

#define NPC_KEY_NAME(k) NPC_KEY_ ## k,

enum {
  NPC_KEY_NONE = 0,
  MAP(NPC_KEYS, NPC_KEY_NAME)
};

#define SDL_KEYMAP(k) keymap[SDL_SCANCODE_ ## k] = NPC_KEY_ ## k;
static uint32_t keymap[256] = {};

static void init_keymap() {
  MAP(NPC_KEYS, SDL_KEYMAP)
}

#define KEY_QUEUE_LEN 1024 //定义环形队列的长度为1024
static int key_queue[KEY_QUEUE_LEN] = {};
static int key_f = 0, key_r = 0; //队列前端（出队）和队列后端（入队）位置

//将键盘扫描码入队，
static void key_enqueue(uint32_t am_scancode) {
  key_queue[key_r] = am_scancode;
  key_r = (key_r + 1) % KEY_QUEUE_LEN;
  if(key_r == key_f){
    printf("key queue overflow!\n");
    assert(1);
    }
}

uint32_t key_dequeue() {
  uint32_t key = NPC_KEY_NONE;
  if (key_f != key_r) {
    key = key_queue[key_f];
    key_f = (key_f + 1) % KEY_QUEUE_LEN;
  }
  return key;
}

void send_key(uint8_t scancode, bool is_keydown) {
  if (npc_state.state == NPC_RUNNING && keymap[scancode] != NPC_KEY_NONE) {
    uint32_t am_scancode = keymap[scancode] | (is_keydown ? KEYDOWN_MASK : 0);
    key_enqueue(am_scancode);
  }
}


static uint32_t *i8042_data_port_base = NULL;

// static void i8042_data_io_handler(uint32_t offset, int len, bool is_write) {
//   assert(!is_write);
//   assert(offset == 0);
//   i8042_data_port_base[0] = key_dequeue();
// }

void init_i8042() {
  i8042_data_port_base = (uint32_t *)malloc(4);
  i8042_data_port_base[0] = NPC_KEY_NONE;
  init_keymap();
}