RAM_ADDR: equ $1000 ; RAM address
STACK_ADDR: equ $2000 ; stack address
DELAY_DURATION: equ $1000

COUNTER: equ 0

  di
  ld sp, STACK_ADDR

main:
  ld ix, RAM_ADDR
  ld (ix+COUNTER), 0 ; initialise counter
  scf ; set carry flag

left:
  rl (ix+COUNTER)
  jp c, right
  ld a, (ix+COUNTER) ; load counter into A
  out ($00), a

  ld bc, DELAY_DURATION
  call delay

  jp left

right:
  rr (ix+COUNTER)
  jp c, left
  ld a, (ix+COUNTER) ; load counter into A
  out ($00), a

  ld bc, DELAY_DURATION
  call delay

  jp right

include 'delay.inc'
