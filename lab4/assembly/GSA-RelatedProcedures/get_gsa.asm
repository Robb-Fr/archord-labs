 .equ GSA, 0x1014
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

; BEGIN:get_gsa
get_gsa:
slli t1,a0,3     #t1 stores the value from 0 to 95, here i do t1 = x*8
add t1,t1,a1     # here i get t1 = x*8 + y
slli t1,t1,2     # t1 is shifted by 2 to get a mutliple of 4
ldw v0, GSA(t1)  # loading the correct GSA square in v0
ret
; END:get_gsa