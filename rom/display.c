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
  for (uint16_t *i = CHAR_RAM; i < (uint16_t *)0x4010; i++) {
    *i = 1;
  }

  while (1) {
    for (uint16_t i = 0; i < 8; i++) {
      for (uint16_t j = 0; j < 2; j++) {
        uint16_t fb_index = (i << 6) | j;
        FRAMEBUFFER[fb_index] = 0xFFFF;
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
