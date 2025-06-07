#include <stdint.h>

// #define LED ((uint8_t *)0x3000)
volatile uint8_t *LED = (uint8_t *)0x3000;

void delay(uint16_t d) {
  for (uint16_t i = 0; i < d; i++) {
    asm("nop");
  }
}

int __attribute__((noreturn)) main() {
  while (1) {
    *LED = 0xFF;
    delay(65535);
    *LED = 0x00;
    delay(65535);
  }
}
