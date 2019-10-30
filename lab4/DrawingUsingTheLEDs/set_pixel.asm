.equ LEDS, 0x2000

; BEGIN:set_pixel
set_pixel:
addi t0, zero, 15  #creating the mask
slli t0,t0,2
and  t1,a0, t0     #forcing last two bits of arguments at zero to get (0 or 4 or 8)
ldw t2, LEDS(t1)   # loading correct word (t1 = 0,4,8)

addi t0,zero, 15   # creating another mask
srli t0,t0,2
and t3, a0, t0    # t3 is the offset 0,1,2,3 to be used to find the correct bit to set at postion (y + offset*8)

addi t4,zero,1    # t4 will be the mask for the correct bit
sll  t4,t4, a1    # t4 has now been shifted by y and will be then shifted by offset*8

beq t3,zero, if_zero

if_not_zero :
slli t4,t4,8                       #shifting by offset*8
addi t3,t3,-1
bne t3, zero, if_not_zero

if_zero :
or t2,t2,t4
stw t2,LEDS(t1)
ret
; END:set_pixel