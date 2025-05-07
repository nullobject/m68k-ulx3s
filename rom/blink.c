#include <stdint.h>

volatile uint8_t *LED = (uint8_t *)0x2000;

void delay(int d) {
  for (int i = 0; i < d; i++) {
    asm("nop");
  }
}

void start(void) {
loop:
  for (int i = 0; i < 8; i++) {
    *LED = 1 << i;
    delay(100000);
  }
  goto loop;
}

void __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");  // Set PC to execute fill()
  __builtin_unreachable();
}
