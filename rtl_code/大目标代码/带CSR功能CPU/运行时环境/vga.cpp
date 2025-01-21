#include "include/include.h"
#include <SDL2/SDL.h>

#define SCREEN_W 400
#define SCREEN_H 300

uint32_t screen_size() {
  return (uint32_t)SCREEN_W * (uint32_t)SCREEN_H * sizeof(uint32_t);
}

void *vmem = NULL;
uint32_t *vgactl_port_base=NULL;

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

void init_screen() {  
  vmem = malloc(screen_size());
  SDL_Window *window = NULL;
  char title[128];
  sprintf(title, "qh-riscv32-npc");
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(
      SCREEN_W*3,
      SCREEN_H*3,
      0, &window, &renderer);
  SDL_SetWindowTitle(window, title);
  //创建一个名为texture的SDL纹理,用于图形渲染，可以被渲染到窗口或屏幕上。
  //SDL_PIXELFORMAT_ARGB8888: 纹理的像素格式,像素由 8 位 Alpha、8 位 Red、8 位 Green 和 8 位 Blue 组成，共 32 位。
  //SDL_TEXTUREACCESS_STATIC: 纹理的访问模式。STATIC 表示纹理内容在运行时不会改变
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
  SDL_RenderPresent(renderer);
  vgactl_port_base = (uint32_t *)malloc(8);
  vgactl_port_base[0] = ((uint32_t)SCREEN_W << 16) | (uint32_t)SCREEN_H;
  vgactl_port_base[1]=0;
}

void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}


void vga_update_screen() {
  // TODO: call `update_screen()` when the sync register is non-zero,
  // then zero out the sync register
  //注意 SYNC_ADDR 是 (VGACTL_ADDR + 4)
  if (vgactl_port_base[1]) {
    update_screen();
    vgactl_port_base[1] = 0;}
}
