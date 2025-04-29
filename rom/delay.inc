; Delays for a duration.
;
; bc - duration
delay:
  dec bc
  ld a, b
  or c
  jp nz, delay
  ret
