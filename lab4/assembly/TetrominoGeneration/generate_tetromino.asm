  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4
; BEGIN:generate_tetromino
generate_tetromino:
    loop:
    ldw t0, RANDOM_NUM(zero)
    andi t0,t0,0x7
    cmpgei t1, t0, 5
    bne t1,zero, loop

    stw t0,T_type(zero) # random tetromino shape
    addi t0,zero,6
    addi t1,zero,1
    addi t2, zero, N
    stw t0, T_X(zero) # x = 6
    stw t1, T_Y(zero) # y = 1
    stw t2, T_orientation(zero) # orientation = North
    
; END:generate_tetromino
