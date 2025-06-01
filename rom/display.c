#include <stdint.h>

#define FRAMEBUFFER ((uint16_t *)0x2000)
#define CHAR_RAM ((uint16_t *)0x4000)

// Address offset of the first printable ASCII character
#define ASCII_OFFSET 0x20

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

void clear_framebuffer() {
  for (uint16_t i = 0; i < 4096; i++) {
    FRAMEBUFFER[i] = 0;
  }
}

void clear_char_ram() {
  for (uint16_t i = 0; i < 256; i++) {
    CHAR_RAM[i] = 0;
  }
}

void write_string(char *s, uint8_t col, uint8_t row) {
  uint8_t index = (row << 5) + col;
  while (*s != '\0') {
    CHAR_RAM[index++] = *s++ - ASCII_OFFSET;
  }
}

void start() {
  clear_char_ram();

  write_string("FREQ    RES     ENV     MODE    \0", 0, 2);
  write_string("1.00    0.01    0.00    LOW PASS\0", 0, 3);
  write_string("----    ----    ----    ----    \0", 0, 4);
  write_string("ATK     DEC     SUS     REL     \0", 0, 5);
  write_string("0.64    1.74    0.34    0.44    \0", 0, 6);
  write_string("----    ----    ----    ----    \0", 0, 7);

  while (1) {
    clear_framebuffer();

    delay(65535);

    for (uint16_t row = 0; row < 8; row++) {
      for (uint16_t col = 0; col < 2; col++) {
        uint16_t index = (row << 6) | col;
        FRAMEBUFFER[index] = 0x7777;
      }
    }

    delay(65535);
  }
}

int __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");
  __builtin_unreachable();
}
