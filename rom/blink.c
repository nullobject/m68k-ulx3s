void start(void) {
  unsigned char *LED = (unsigned char *)0x2000;
  *LED = 0x1f;
stop:
  goto stop;
}

void __attribute__((noreturn)) main(void) {
  asm("dc.l 0x2000"); // Set stack to top of RAM
  asm("dc.l start");  // Set PC to execute fill()
  __builtin_unreachable();
}
