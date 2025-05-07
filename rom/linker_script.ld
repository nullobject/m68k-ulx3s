MEMORY
{
  ROM_VECTORS (RX) : ORIGIN = 0x00, LENGTH = 0x10
  ROM_CODE    (RX) : ORIGIN = 0x10, LENGTH = 0x1000
}

SECTIONS
{
  .text.startup :
  {
    *(.text.startup)
  } > ROM_VECTORS

  .text :
  {
    *(.text)
  } > ROM_CODE
}

OUTPUT_FORMAT(binary)
