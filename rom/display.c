#include <stdint.h>

#include "tiles.h"

#define FRAMEBUFFER (uint16_t *)0x2000

void delay(int d) {
  for (int i = 0; i < d; i++) {
    asm("nop");
  }
}

void start(void) {
  uint16_t *p;
  while (1) {
    p = FRAMEBUFFER;

    for (uint16_t i = 0; i < 8; i++) {
      for (uint16_t j = 0; j < 2; j++) {
        uint16_t offset = 0x400;
        uint16_t index1 = (i << 6) + j;
        uint16_t index2 = (i << 2) + (j << 1);
        p[index1] = (tiles[offset + index2 + 1] << 8) + tiles[offset + index2];
      }
    }

    delay(100000);

    for (uint16_t *i = FRAMEBUFFER; i < (uint16_t *)0x4000; i++)
      *i = 0x0000;

    delay(100000);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
