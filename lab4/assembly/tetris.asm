  ;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
  .equ LEDS, 0x2000                 ; LED address
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ BUTTONS, 0x2030              ; Buttons addresses

  ;; type enumeration
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04

  ;; GSA type
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

  ;; orientation enumeration
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4

  ;; collision boundaries
  .equ COL_X, 4
  .equ COL_Y, 3

  ;; Rotation enumeration
  .equ CLOCKWISE, 0
  .equ COUNTERCLOCKWISE, 1

  ;; Button enumeration
  .equ moveL, 0x01
  .equ rotL, 0x02
  .equ reset, 0x04
  .equ rotR, 0x08
  .equ moveR, 0x10
  .equ moveD, 0x20

  ;; Collision return ENUM
  .equ W_COL, 0
  .equ E_COL, 1
  .equ So_COL, 2
  .equ OVERLAP, 3
  .equ NONE, 4

  ;; start location
  .equ START_X, 6
  .equ START_Y, 1

  ;; game rate of tetrominoe falling down (in terms of game loop iteration)
  .equ RATE, 5

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8


; BEGIN:main
main:
	addi sp, zero, 0x1FFC

	call reset_game

	game:
		falling:
			addi s1, zero, RATE
			rate:
				addi s1, s1, -1
				call draw_gsa
				call display_score
			
				addi a0, zero, NOTHING
				call draw_tetromino
	
				call wait
			
				call get_input

				beq v0, zero, no_input

				add a0, zero, v0
				call act

				no_input:

				addi a0, zero, FALLING
				call draw_tetromino

				bne s1, zero, rate

			addi a0, zero, NOTHING
			call draw_tetromino

			addi a0, zero, moveD
			call act
			add s1, zero, v0

			addi a0, zero, FALLING
			call draw_tetromino

			beq s1, zero, falling

		addi a0, zero, PLACED
		call draw_tetromino

		full_lines:
	
			call detect_full_line
			addi t0, zero, 8
	
			beq v0, t0, no_more_full
			add a0, zero, v0
			
			call remove_full_line
			call increment_score
			br full_lines

		no_more_full:

		call generate_tetromino

		addi a0, zero, OVERLAP
		call detect_collision
		
		addi t0, zero, NONE
		bne v0, t0, failed

		addi a0, zero, FALLING
		call draw_tetromino

		br game

	failed:	
		br main
; END:main
	

; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
	ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	srli t0, a0, 2
	slli t0, t0, 2		# t0 = (x/4)*4
	ldw t1, LEDS(t0)	# loading correct word (t1 = 0,4,8)

	slli t2, a0, 3
	add t2, t2, a1
	andi t2, t2, 0x1F	# t2 = (8*x+y)%32

	addi t3, zero, 1
	sll t3, t3, t2		# t3 = 1 << (8*x+y)%32

	or t1, t1, t3
	
	stw t1, LEDS(t0)

	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi a0, zero, 0x1
	slli a0, a0, 20				# sets the 20th bit to 1 in order to have 2^20

	count_down:
		addi a0, a0, -1 			# decrement argument by 1
		bne a0, zero, count_down	# compare a0 to 0 and restart if not equal

	ret
; END:wait

; BEGIN:get_gsa
get_gsa:
	slli t1, a0, 3     		# t1 = x*8
	add t1, t1, a1     		# t1 = x*8 + y
	slli t1, t1, 2     		# t1 = t1*4 (valid word address)
	ldw v0, GSA(t1)  		# v0 = GSA(x,y)
	ret
; END:get_gsa

; BEGIN:in_gsa
in_gsa:
	addi t0, zero, 12			# t0 = x max
	addi t1, zero, 8			# t1 = y max

	blt a0, zero, flag_outside	# if x < 0
	bge a0, t0, flag_outside	# if x ≥ 12
	blt a1, zero, flag_outside	# if y < 0
	bge a1, t1, flag_outside	# if y ≥ 8

	br is_ok					# all tests passed

	flag_outside:
		addi v0, zero, 1		# set flag on
		ret
	is_ok:
		add v0, zero, zero		# set no flag
		ret
; END:in_gsa

; BEGIN:set_gsa
set_gsa:
	slli t1, a0, 3    	# t1 = x*8
	add t1, t1, a1     	# t1 = x*8 + y
	slli t1, t1, 2      # t1 = t1*4 (valid address)

	stw a2, GSA(t1)   	# storing p taking value in (NOTHING,PLACED,FALLING) in GSA(x,y)
	
	ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -20
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)

	add s0, zero, zero	# x
	add s1, zero, zero	# y
	addi s2, zero, 11	# x max
	addi s3, zero, 7	# y max

	call clear_leds		# takes no arguments
	
	loop_draw:
		add a0, zero, s0			# set a0 to x
		add a1, zero, s1			# set a1 to y
		call get_gsa				# v0 stores GSA(x,y)
		
		add a0, zero, s0			# set a0 to x
		add a1, zero, s1			# set a1 to y
		beq v0, zero, next_draw		# if (GSA(x,y) == 0) no need to set pixel
		call set_pixel
		
		next_draw:
			beq s1, s3, next_j_draw		# if (y == y max) increment x
			addi s1, s1, 1				# else increment y
			br loop_draw
			next_j_draw:
				beq s0, s2, end_draw	# if (x == x max) end loop
				add s1, zero, zero		# else restart y
				addi s0, s0, 1			# increment x
				br loop_draw

	end_draw:
		ldw ra, 0(sp)
		ldw s0, 4(sp)
		ldw s1, 8(sp)
		ldw s2, 12(sp)
		ldw s3, 16(sp)
		addi sp, sp, 20
			
		ret
; END:draw_gsa

; BEGIN:draw_tetromino
draw_tetromino:
	addi sp, sp, -28
	stw ra, 0(sp)            
	stw s0, 4(sp)
	stw s1, 8(sp)       	
	stw s2, 12(sp)
    stw s3, 16(sp)
	stw s4, 20(sp)
	stw s5, 24(sp)			# stack = top -> ra/s0/s1/s2/s3/s4/s5

	ldw s1, T_X(zero)  		# s1 = x position of the anchor point
	ldw s2, T_Y(zero)  		# s2 = y position of the anchor point
	add s5, a0, zero     	# s5 stores the p value of the GSA

	add a0, s1, zero   		# setting the arguments for set_gsa call
	add a1, s2, zero
	add a2, s5, zero

	call set_gsa       		# set the anchor point in the gsa

	ldw t0, T_type(zero)
	ldw t1, T_orientation(zero)
	slli t0, t0, 2
	add t0, t0, t1     
	slli t0, t0, 2         	# t0 = (T_type*4 + T_orientation) << 2
    ldw s3, DRAW_Ax(t0)  	# s3 stores the pointer to the offset array x
    ldw s4, DRAW_Ay(t0)  	# s4 stores the pointer to the offset array y
	addi s0, s3, 12 		# loop limit

	# this loop sets the gsa for the surrouding point around the anchor point
	mini_loop:                               
		beq s3, s0, return_time
		ldw t1, 0(s3) 		# offset in array for x axis
		ldw t2, 0(s4) 		# offset in array for y axis
        
		add a0, s1, t1      # ao = x + offset
		add a1, s2, t2      # a1 = y + offset
		add a2, zero, s5	# a2 = p value

		call set_gsa        # set the surrounding gsas around the anchor gsa

		addi s3, s3, 4
        addi s4, s4, 4
		br mini_loop


	return_time:
		ldw s5, 24(sp)
		ldw s4, 20(sp)
        ldw s3, 16(sp)
		ldw s2, 12(sp)
		ldw s1, 8(sp)
		ldw s0, 4(sp)
		ldw ra, 0(sp)
		addi sp, sp, 28
	ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
	loop:
		ldw t0, RANDOM_NUM(zero)
		andi t0, t0, 0x7			# t0 = RANDOM_NUM
		cmpgei t1, t0, 5			# t1 = t0 ≥ 5 ? 1 : 0
		bne t1, zero, loop			# if (t1 > 4) generate new tetromino

		stw t0, T_type(zero) 		# random tetromino shape in [0,4]
		addi t0, zero, 6			# t0 = 6
		addi t1, zero, 1			# t1 = 1
		addi t2, zero, N			# t2 = N
		stw t0, T_X(zero) 			# x = 6
		stw t1, T_Y(zero) 			# y = 1
		stw t2, T_orientation(zero) # orientation = North
	ret
; END:generate_tetromino


; BEGIN:detect_collision
detect_collision:
# the idea is to get the current tetromino coordinates via T_type and T_orientation which gives us the index in DRAW_Ax and DRAW_Ay
# then if we have a SO_COl, we increment every y coordinate, we check for each if in_gsa and then get_gsa and check if is 1 or not
# for W_COl, we decrement every x coordinate
# for E_COL we increment every x coordinate
# for OVERLAP, we directly check the current coordinates
# for NONE, output NONE
	addi sp,sp,-28      	# pushing return adress and saved registers on the stack
	stw ra, 0(sp)            
	stw s0, 4(sp)
	stw s1, 8(sp)       	# stack = top -> ra/s0/s1/s2/s3/s4/s5
	stw s2, 12(sp)
    stw s3, 16(sp)
	stw s4, 20(sp)
	stw s5, 24(sp)

    add s1, zero, a0	 	# s1 stores the collision we are interested in
	ldw t0, T_type(zero)
	ldw t1, T_orientation(zero)
	slli t0, t0, 2
	add t0, t0, t1     
	slli t0, t0, 2         	# t0 = (T_type*4 + T_orientation) << 2
    ldw s3, DRAW_Ax(t0)  	# s3 stores the pointer to the offset array for x
    ldw s4, DRAW_Ay(t0)  	# s4 stores the pointer to the offset array for y
	

	# in_gsa and get_gsa only use register t0 and t1, we are safe to use the others
    setup:
		ldw a0, T_X(zero)				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a2, zero, s1				# the collision

		call incrementOrDecrement		# will change the value of x and y accordingly

		call in_gsa
		bne v0, zero, collision_exist	# would be out of gsa so collision

		ldw a0, T_X(zero)				# putting back the arguments because they are caller-saved
 		ldw a1, T_Y(zero) 			
		add a2, zero, s1

		call incrementOrDecrement

		call get_gsa
		addi t0, zero, PLACED
		beq v0, t0, collision_exist

		addi s0, s3, 12					# loop limit for iterating over tetrominoes

	loop_collision:                     # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3, s0, no_collision
		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate

		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		add a2, zero,s1 

		call incrementOrDecrement

		call in_gsa
		bne  v0, zero, collision_exist    # would be out of gsa so collision


		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1, t2         			# a1 = y + offset
		add a2, zero, s1 

		call incrementOrDecrement

		
		call get_gsa

		addi t0, zero, PLACED
		beq v0, t0, collision_exist

		addi s3, s3, 4
        addi s4, s4, 4

		br loop_collision

	collision_exist:
		add v0, zero, s1 		# the collision exists so we return the input
		br return_collision

	no_collision:
        addi v0, zero, NONE  	# the collison doesn't exist so we return NONE
	
	return_collision:
		ldw s5, 24(sp)
		ldw s4, 20(sp)
        ldw s3, 16(sp)
		ldw s2, 12(sp)
		ldw s1, 8(sp)
		ldw s0, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,28
		ret
; END:detect_collision


; BEGIN:helper
incrementOrDecrement:
# a0 is the x coordinate
# a1 is the y coordinate
# a2 is the type of collision

addi t0, zero, E_COL
addi t1, zero, W_COL
addi t2, zero, So_COL
addi t3, zero, OVERLAP

beq a2, t0, east
beq a2, t1, west
beq a2, t2, south
beq a2, t3, nothing_left

east:
addi a0, a0, 1
br nothing_left

west: 
addi a0, a0, -1
br nothing_left

south:
addi a1 ,a1, 1
br nothing_left

nothing_left:
ret
; END:helper

; BEGIN:rotate_tetromino
rotate_tetromino:
# the idea is to decrement if left rotation else increment 
# the current orientation, and then masking the last 2 bits
	addi t4, zero, rotL
	ldw t5, T_orientation(zero)
	andi t5, t5, 0x3
	beq a0, t4, left

	right:
	addi t5, t5, 1
	br back

	left:
	addi t5, t5, -1

	back:
	andi t5, t5, 0x3
	stw t5, T_orientation(zero)
	ret
; END:rotate_tetromino

; BEGIN:act
act:
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)  		# stack looks like : top -> ra/s0/s1/s2

	addi t0, zero, moveL
	addi t1, zero, rotL
	addi t2, zero, reset
	addi t3, zero, rotR
	addi t4, zero, moveR
	addi t5, zero, moveD
	
	beq a0,t0,leftmove
	beq a0,t1,rotate
	beq a0,t2,reboot
	beq a0,t3,rotate
	beq a0,t4,rightmove
	beq a0,t5,downmove

leftmove:
	addi s0,zero, W_COL
	addi a0, zero, W_COL
	call detect_collision		
	beq s0,v0,unchanged		# if collision occurs, don't move
	ldw t1,T_X(zero)
	addi t1,t1,-1
	stw t1,T_X(zero)
	br changed

rightmove:
	addi s0,zero, E_COL
	addi a0, zero, E_COL
	call detect_collision
	beq s0, v0, unchanged
	ldw t1, T_X(zero)
	addi t1, t1, 1
	stw t1, T_X(zero)
	br changed

downmove:
	addi s0, zero, So_COL
	addi a0, zero, So_COL
	call detect_collision
	beq s0, v0, unchanged
	ldw t1, T_Y(zero)
	addi t1, t1, 1
	stw t1, T_Y(zero)
	br changed


rotate:
	ldw s0, T_orientation(zero)
	ldw s1, T_X(zero)				# storing the original position of the tetromino
	ldw s2, T_Y(zero)
	call rotate_tetromino          	# changing T_orientation
	addi a0,zero,OVERLAP
	call detect_collision
	addi t0,zero,NONE
	beq v0,t0,changed				# if no collison then all good
	ldw t0, T_X(zero)
	addi t1,zero,6	
	blt t0,t1,to_the_right	       	# now we have to move the tetromino towards the center but we don't know which side of the grid we are on

	to_the_left:
	ldw t0,T_X(zero)								
	addi t0,t0,-1
	stw t0,T_X(zero)
	addi a0,zero,OVERLAP
	call detect_collision			# trying if overlap but moved to the left once
	addi t0,zero,NONE
	beq v0,t0,changed
	ldw t0,T_X(zero)								
	addi t0,t0,-1
	stw t0,T_X(zero)
	addi a0,zero,OVERLAP
	call detect_collision			# trying if overlap but moved to the left twice
	addi t0,zero,NONE
	beq v0,t0,changed							
	stw s0,T_orientation(zero)		# didn't work so we go back to previous values
	stw s1,T_X(zero)
	stw s2,T_Y(zero)
	br unchanged
	
	to_the_right:
 		ldw t0,T_X(zero)								
		addi t0,t0,1
		stw t0,T_X(zero)
		addi a0,zero,OVERLAP
		call detect_collision		# trying if overlap but moved to the left once
		addi t0,zero,NONE
		beq v0,t0,changed
		ldw t0,T_X(zero)								
		addi t0,t0,1
		stw t0,T_X(zero)
		addi a0,zero,OVERLAP
		call detect_collision		# trying if overlap but moved to the left twice
		addi t0,zero,NONE
		beq v0,t0,changed							
		stw s0,T_orientation(zero)	# didn't work so we go back to previous values
		stw s1,T_X(zero)
		stw s2,T_Y(zero)
		br unchanged	

unchanged:
	ldw s2,12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp,sp,16
	addi v0,zero,1 		# 1 if failed to act
	ret
changed:

	ldw s2,12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp,sp,16
	add v0,zero,zero 	# 0 if succeeded to act
	ret
reboot: 
	ldw s2,12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp,sp,16
	call reset_game
	ret
; END:act

; BEGIN:get_input
get_input:
	ldw	 t0,BUTTONS+4(zero)			# t0 stores edgecapture (edgecapture is at BUTTON+4)
	andi t0, t0, 31					# we want only the last 5 bits
	add t4, zero, zero				# bit counter 
	
tom_loop:
	beq t0, zero, no_input_back		# if (no more bits) stop
	andi t1, t0, 1					# else t1 = last bit of t0
	bne t1, zero, yes_input_back	# if (bit set to 1) return corresponding action
	srli t0, t0, 1
	addi t4, t4, 1					# prepare next bit of t0 and increment counter
	br tom_loop

yes_input_back:
	addi v0, zero, 1
	sll v0, v0, t4
	br end_get_input

no_input_back:
	add v0, zero, zero

end_get_input:
	stw zero, BUTTONS+4(zero)

	ret
; END:get_input

; BEGIN:detect_full_line
detect_full_line:
	addi sp, sp, -24
	stw s0, 0(sp)
	stw s1, 4(sp)
	stw s2, 8(sp)
	stw s3, 12(sp)
	stw s4, 16(sp)
	stw ra, 20(sp)
	addi s0, zero, PLACED	# s0 = PLACED
	add s1, zero, zero		# s1 = x
	add s2, zero, zero		# s2 = y
	addi s3, zero, 12		# s3 = x max
	addi s4, zero, 8		# s4 = y max
	
	loop_full_line:
		add a0, zero, s1
		add a1, zero, s2
		call get_gsa
		and s0, s0, v0					# s0 = is v0 PLACED
		addi s1, s1, 1
		blt s1, s3, loop_full_line		# loop while(x < 12)
	
		next_y_full_line:
			bne s0, zero, happy_ending	# if (whole line is PLACED) return it was detected
			addi s0, zero, 1			# else s0 = PLACED
			add s1, zero, zero			# x = 0
			addi s2, s2, 1				# y += 1
			blt s2, s4, loop_full_line	# loop while (y < 8)

		epic_loss:
			addi v0, zero, 8
			br end_detect_full_line
	
		happy_ending:
			add v0, zero, s2

	end_detect_full_line:
	ldw s0, 0(sp)
	ldw s1, 4(sp)
	ldw s2, 8(sp)
	ldw s3, 12(sp)
	ldw s4, 16(sp)
	ldw ra, 20(sp)
	addi sp, sp, 24
	
	ret		
; END:detect_full_line

; BEGIN:remove_full_line
remove_full_line:
	addi sp,sp,-24
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp) 
	 		

	addi t0,zero,8
	beq a0,t0, back_to_the_game   	# if a0 = 8 then do nothing 

	add s0,zero,a0					# s0 stores the y coordinate of the line to removve		
	addi  s2,zero,4       		 	# blink counter
blink:
	addi s1,zero,11
	
off:
	add a0,s1,zero					# x coordinate of the current gsa block
	add a1,s0,zero					# y coordinate of the line
	add a2,zero,zero				# set the line off
	
	call set_gsa
	
	addi s1,s1,-1			
	cmplt t7,s1,zero	
	bne t7,zero,off

	call draw_gsa
	call wait
	addi s2,s2,-1
	beq s2,zero,make_lines_go_down
	addi s1,zero,11

on:
	add a0,s1,zero					# x coordinate
	add a1,s0,zero					# y coordinate
	addi a2,zero,1					# set the line on
	
	call set_gsa
	
	addi s1,s1,-1			
	cmplt t7,s1,zero	
	bne t7,zero,on

	call draw_gsa
	call wait
	addi s2,s2,-1
	br blink

make_lines_go_down:
	add s2, zero,s0					# s2 stores the current y coordinate of the line to modifiy
	add s1,zero,zero				# s1 stores the current x coordinate of the gsa to be modified
	addi s3,zero,12					# s3 is the loop limit on the x coordinate
	addi s4,zero,1					# s4 is the loop limit on the y coordinate



	
 move_line_down:
	beq s2,s4,back_to_the_game
	add s1,zero,zero   				# reset the x coordinate

	loop_over_gsa:
		beq s1,s3,cont2
		add a0,s1,zero  			# a0 = x coordinate
		addi a1,s2,-1     			# a1 = y - 1
		call get_gsa

		andi v0,v0,1      			# forcing v0 to be either NOTHING OR PLACED

		add a0,s1,zero  			# a0 = x coordinate
		add a1,s2,zero     			# a1 = y coordinate
		add a2,v0,zero    			# a2 = element on top of (x,y)
		call set_gsa

	cont1: 
	addi s1,s1,1      				# incrementing the x coordinate
	br loop_over_gsa   
	cont2:
	addi s2,s2,-1     				# moving up the gsa array
	br move_line_down



back_to_the_game:
	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp,sp,24	
	ret

; END:remove_full_line

; BEGIN:increment_score
increment_score:
	ldw t0, SCORE(zero)
	addi t1, zero, 9999
	addi t0, t0, 1

	bge t0, t1, ceiling		# if (SCORE+1 ≥ 9999) SCORE = 9999
	stw t0, SCORE(zero)
	ret

	ceiling:
	stw t1, SCORE(zero)		
	ret
; END:increment_score

; BEGIN:display_score
display_score:
	addi sp, sp, -4
	stw ra, 0(sp)
	ldw t0, SCORE(zero)		# t0 = SCORE
	add t1, zero, zero		# t1 = digit 0
	add t2, zero, zero		# t2 = digit 1
	add t3, zero, zero		# t3 = digit 2
	add t4, zero, zero		# t4 = digit 3
	
	get_digits:
		add a0, zero, t0
		addi a1, zero, 1000
		call deci_divide
		add t4, v0, zero
		
		add a0, zero, v1
		addi a1, zero, 100
		call deci_divide
		add t3, v0, zero

		add a0, zero, v1
		addi a1, zero, 10
		call deci_divide
		add t2, v0, zero
		add t1, v1, zero
	
	digits_assign:
		slli t1, t1, 2
		slli t2, t2, 2
		slli t3, t3, 2
		slli t4, t4, 2

		ldw t1, font_data(t1)
		ldw t2, font_data(t2)
		ldw t3, font_data(t3)
		ldw t4, font_data(t4)
		
		stw t1, SEVEN_SEGS+12(zero)
		stw t2, SEVEN_SEGS+8(zero)
		stw t3, SEVEN_SEGS+4(zero)
		stw t4, SEVEN_SEGS(zero)

		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
		
; END:display_score
; BEGIN:helper
# a0 : the numerator
# a1 : the denominator
# v0 : the quotient
# v1 : the remainder
deci_divide:
	add v0, zero, zero
	loop_deci_divide:
		blt a0, a1, end_deci_divide
		sub a0, a0, a1
		addi v0, v0, 1
		br loop_deci_divide
	end_deci_divide:
		add v1, zero, a0
		ret
; END:helper

; BEGIN:reset_game
reset_game:
	addi sp, sp, -24
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp) 

	stw zero, SCORE(zero) # reset the score to zero

	# resetting the entire gsa

	addi s0 , zero, -1		# loop limit for both loops
	addi s1, zero, 11 		# s1 = current x coordinate 
	addi s2, zero, 7  		# s2 = current y coordinate

	loop_over_y:
		beq s2, s0, put_tetromino
		addi s1, zero, 11

	loop_over_x:
		beq s1, s0, conty
		add a0, s1, zero   
		add a1, s2, zero		# setting the arguments for set_gsa
		addi a2, zero, NOTHING 
		call set_gsa
		addi s1, s1, -1
		br loop_over_x

	conty:
		addi s2, s2, -1
		br loop_over_y

	put_tetromino:
		call generate_tetromino
		addi a0, zero, FALLING
		call draw_tetromino

	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 24
	
	ret
; END:reset_game

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
