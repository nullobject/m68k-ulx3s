MEMORY
{
  rom (rx)  : ORIGIN = 0x0000, LENGTH = 0x1000
  ram (rwx) : ORIGIN = 0x1000, LENGTH = 0x1000
}

SECTIONS
{
  .text :
  {
    KEEP(*(.vectors .vectors.*))
    . = ALIGN(2);
    _stext = .;
    *(.text .text.*)
    *(.rodata .rodata.*)
    . = ALIGN(2);
    _etext = .;
  } > rom

  .data :
  {
    . = ALIGN(2);
    _sdata = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(2);
    _edata = .;
  } > ram AT> rom

  .bss :
  {
    . = ALIGN(2);
    _sbss = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(2);
    _ebss = .;
  } > ram
}
