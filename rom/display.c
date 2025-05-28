#include <stdint.h>

#define FRAMEBUFFER (uint16_t *)0x2000

void delay(int d) {
  for (int i = 0; i < d; i++) {
    asm("nop");
  }
}

void start(void) {
  while (1) {
    for (uint16_t *i = FRAMEBUFFER; i < (uint16_t *)0x4000; i++)
      *i = 0xFFFF;

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
