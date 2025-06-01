#include <stdint.h>

#define FRAMEBUFFER ((uint16_t *)0x2000)
#define CHAR_RAM ((uint16_t *)0x4000)

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
  for (uint16_t i = 0; i < 256; i++) {
    CHAR_RAM[i] = i & 0x3F;
  }

  while (1) {
    for (uint16_t row = 0; row < 8; row++) {
      for (uint16_t col = 0; col < 2; col++) {
        uint16_t index = (row << 6) | col;
        FRAMEBUFFER[index] = 0x7777;
      }
    }

    delay(65535);

    for (uint16_t i = 0; i < 0x1000; i++) {
      FRAMEBUFFER[i] = 0;
    }

    delay(65535);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
