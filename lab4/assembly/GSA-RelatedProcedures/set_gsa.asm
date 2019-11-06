.equ NOTHING, 0x0
.equ PLACED, 0x1
.equ FALLING, 0x2
.equ GSA, 0x1014 

; BEGIN:set_gsa
set_gsa:
slli t1,a0,3     # t1 stores the value between 0 and 95, here i do t1 = x*8
add t1,t1,a1     # i do t1 = x*8 + y
slli t1,t1,2      # shifting t1 by 2 to get a multiple of 4

stw a2, GSA(t1)   # storing p taking value in (NOTHING,PLACED,FALLING) in the correct GSA square
ret
; END:set_gsa
