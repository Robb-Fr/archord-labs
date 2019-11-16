  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2
  .equ GSA, 0x1014 

; BEGIN:draw_tetromino
draw_tetromino:
 addi sp,sp,-16      #pushing return adress and saved registers on the stack
 stw ra, 0(sp)            
 stw s0, 4(sp)
 stw s1, 8(sp)       # stack = top -> ra/s0/s1/s2
 stw s2, 12(sp)


 ldw s1, T_X(zero)  #s1 = x position of the anchor point
 ldw s2, T_Y(zero)  #s2 = y position of the anchor point
 add a2,a0,zero     # a2 stores the p value of the GSA
 add a0, s1, zero   # setting the arguments for set_gsa
 add a1, s2, zero

 call set_gsa       # setting the anchor point in the gsa

 ldw t0, T_type(zero)
 ldw t1, T_orientation(zero)
 slli t0,t0,2
 add t0,t0,t1     
 slli s0,t0,2         # s0 = (T_type*4 + T_orientation) << 2
 addi t3,s0,12 # loop limit

 mini_loop:                               # this loop sets the gsa for the surrouding point around the anchor point
  beq s0,t3, return_time
   ldw t1, DRAW_Ax(s0)  # offset in array for x axis
   ldw t2, DRAW_Ay(s0)  # offset in array for y axis
   add a0, s1, t1        # ao = x + offset
   add a1, s2,t2         # a1 = y + offset
   call set_gsa          # set the surrounding gsas around the anchor gsa
   addi s0,s0,4
 br mini_loop


return_time:

ldw s2,12(sp)
ldw s1, 8(sp)
ldw s0, 4(sp)
ldw ra, 0(sp)
addi sp,sp,16
ret
; END:draw_tetromino


; BEGIN:set_gsa
set_gsa:
slli t1,a0,3     # t1 stores the value between 0 and 95, here i do t1 = x*8
add t1,t1,a1     # i do t1 = x*8 + y
slli t1,t1,2      # shifting t1 by 2 to get a multiple of 4

stw a2, GSA(t1)   # storing p taking value in (NOTHING,PLACED,FALLING) in the correct GSA square
ret
; END:set_gsa



font_data:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y
