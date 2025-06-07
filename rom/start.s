.section .vectors

vectors:

dc.l 0x2000
dc.l start

start:

/* copy data section */
movea.l #_etext, %a0
movea.l #_sdata, %a1
movea.l #_edata, %a2
loop_init_data:
cmpa.l %a2, %a1       /* check if start < end */
bge end_init_data
move.w %a0@+, %a1@+   /* copy a word from ROM to RAM */
bra loop_init_data
end_init_data:

/* zero-init bss section */
movea.l #_sbss, %a0
movea.l #_ebss, %a1
loop_init_bss:
cmpa.l %a1, %a0       /* check if start < end */
bge end_init_bss
clr.w %a0@+           /* clear word and increment start */
bra loop_init_bss
end_init_bss:

jmp main
