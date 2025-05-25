#include <stdint.h>

#define RDRF 0
#define TDRE 1

volatile uint8_t *LED = (uint8_t *)0x2000;
volatile uint8_t *ACIA_CTRL = (uint8_t *)0x3000;
volatile uint8_t *ACIA_DATA = (uint8_t *)0x3002;

void delay(int d) {
  for (int i = 0; i < d; i++) {
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

void start(void) {
  char *line = "hello world!\n\r";
  char c = 0;

  serial_init();

  while (1) {
    line[0] = '0' + (7 & c++);
    cout(line);
    delay(100000);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
