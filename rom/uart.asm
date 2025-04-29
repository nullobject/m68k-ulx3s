STACK_ADDR: equ $2000 ; stack address
DELAY_DURATION: equ $8000

LED: equ $00
ACIA_CTRL: equ $80
ACIA_DATA: equ $81

  di
  ld sp, STACK_ADDR
  ; master reset
  ld a, $3
  out (ACIA_CTRL), a
  ; control register (8N1, 9600 baud, receive interrupt enable)
  ld a, $95
  out (ACIA_CTRL), a
  ; enable interrupts
  im 1
  ei
  jp main
  ds $38-$

; Interrupt handler
rst38:
  ex af, af'
  exx
  in a, (ACIA_DATA)
  out (LED), a
  exx
  ex af, af'
  ei
  reti

main:
  ld hl, msg
  call print
  ld bc, DELAY_DURATION
  call delay
  jp main

; Prints a message
;
; hl - pointer to the message
print:
  ld a, (hl)
  cp 0
  ret z
  inc hl
  call .print_char
  jp print

.print_char:
  push af

.wait:
  in a, (ACIA_CTRL)
  bit 1, a
  jp z, .wait
  pop af
  out (ACIA_DATA), a
  ret

include './delay.inc'

msg:
  db "hello world!\r\n", 0
