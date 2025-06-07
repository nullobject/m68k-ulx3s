#include <stdint.h>

#define RDRF 0
#define TDRE 1

volatile uint8_t *ACIA_CTRL = (uint8_t *)0x4000;
volatile uint8_t *ACIA_DATA = (uint8_t *)0x4002;

void delay(uint16_t d) {
  for (uint16_t i = 0; i < d; i++) {
    asm("nop");
  }
}

void serial_init(void) {
  *ACIA_CTRL = 3; // reset ACIA
  delay(10000);
  *ACIA_CTRL = 0x95; // RTS enabled 9600
}

void cout(char *a) {
  for (; *a != 0; a++) {
    while ((*ACIA_CTRL & (1 << TDRE)) == 0) {
      // wait
    }
    *ACIA_DATA = *a;
  }
}

int __attribute__((noreturn)) main(void) {
  char *line = "hello world!\n\r";
  char c = 0;

  serial_init();

  while (1) {
    line[0] = '0' + (7 & c++);
    cout(line);
    delay(65535);
  }

  __builtin_unreachable();
}
