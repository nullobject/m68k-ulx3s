#include <stdbool.h>
#include <stdint.h>

volatile uint8_t *VRAM = (uint8_t *)0x2000;
volatile uint8_t *LED = (uint8_t *)0x5000;

void delay(int d) {
  for (int i = 0; i < d; i++) {
    asm("nop");
  }
}

void start(void) {
  while (1) {
    *VRAM = 0xFF;
    delay(100000);

    *VRAM = 0;
    delay(100000);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
