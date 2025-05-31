#include <stdint.h>

#include "tiles.h"

#define FRAMEBUFFER ((uint16_t *)0x2000)

void delay(uint16_t d) {
  for (uint16_t i = 0; i < d; i++) {
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
  }
}

void start(void) {
  uint16_t tile_offset = 0x400;

  while (1) {
    for (uint16_t i = 0; i < 8; i++) {
      for (uint16_t j = 0; j < 2; j++) {
        uint16_t fb_index = (i << 6) | j;
        uint16_t tile_index = (i << 2) | (j << 1);
        FRAMEBUFFER[fb_index] = (tiles[tile_offset + tile_index + 1] << 8) |
                                tiles[tile_offset + tile_index];
      }
    }

    delay(65535);

    for (uint16_t *i = FRAMEBUFFER; i < (uint16_t *)0x4000; i++)
      *i = 0x0000;

    delay(65535);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
