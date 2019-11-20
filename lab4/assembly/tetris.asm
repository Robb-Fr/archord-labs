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

main:
   #	addi sp,sp,-12
	#	stw s1,8(sp)
	#stw s0,4(sp)
	#stw ra,0(sp)
begin:
	addi s0,zero,5  #s0 = RATE
	call reset_game

play:
 
	can_move_down:
		add s1,zero,s0  # s1 is i
		user_input:
			call draw_gsa
			call display_score
			addi a0,zero,NOTHING
			call draw_tetromino
			call wait
			call get_input
			beq v0,zero,no_input
			add a0,v0,zero
			call act
			no_input:
				call a0,zero,FALLING
				call draw_tetromino


	addi a0, zero, NOTHING
	call draw_tetromino
	addi a0,zero,moveD
	call act
	bne v0,zero,can_move_down     # can stil move the current tetromino
	add a0,zero,PLACED
	call draw_tetromino
	
			 is_there_full_line:
				call detect_full_line
				addi t0,zero,8
				beq v0,t0,check_over
				call increment_score
				add a0,v0,zero
				call remove_full_line
				br is_there_full_line
						
	
check_over:
	call generate_tetromino        # generate new tetromino and check if we haven't lost
	addi a0,zero,OVERLAP
	call detect_collision
	addi t0,zero,OVERLAP
	bne  v0,t0,play
	br begin
	

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
	andi t2, t2, 0x3F	# t2 = (8*x+y)%32

	addi t3, zero, 1
	sll t3, t3, t2		# t3 = 1 << (8*x+y)%32

	or t1, t1, t3
	
	stw t1, LEDS(t0)

	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi a0, zero, 0x1
	slli a0, a0, 5					# sets the 20th bit to 1 in order to have 2^20

	count_down:
		addi a0, a0, -1 			# decrement argument by 1
		bne a0, zero, count_down	# compare a0 to 0 and restart if not equal

	ret
; END:wait

; BEGIN:get_gsa
get_gsa:
	slli t1, a0, 3     		# t1 stores the value from 0 to 95, here i do t1 = x*8
	add t1, t1, a1     		# here i get t1 = x*8 + y
	slli t1, t1, 2     		# t1 is shifted by 2 to get a mutliple of 4
	ldw v0, GSA(t1)  		# loading the correct GSA square in v0
	ret
; END:get_gsa

; BEGIN:in_gsa
in_gsa:
	addi t0, zero, 12			# x must not get to this value
	addi t1, zero, 8			# y must not get to this value	

	blt a0, zero, flag_outside	# if x < 0
	bge a0, t0, flag_outside	# if x ≥ 12
	blt a1, zero, flag_outside	# if y < 0
	bge a1, t1, flag_outside	# if y ≥ 8

	br is_ok					# all tests passed

	flag_outside:
		addi v0, zero, 1		# set flag on
		br return
	is_ok:
		add v0, zero, zero		# set no flag
		br return

	return:
	ret
; END:in_gsa

; BEGIN:set_gsa
set_gsa:
	slli t1, a0, 3    	# t1 stores the value between 0 and 95, here i do t1 = x*8
	add t1, t1, a1     	# i do t1 = x*8 + y
	slli t1, t1, 2      # shifting t1 by 2 to get a multiple of 4

	stw a2, GSA(t1)   	# storing p taking value in (NOTHING,PLACED,FALLING) in the correct GSA square
	
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

	call clear_leds
	
	loop_draw:
		add a0, zero, s0
		add a1, zero, s1
		call get_gsa
		
		add a0, zero, s0
		add a1, zero, s1			#putting back the arguments because they are caller-saved
		beq v0, zero, next_draw
		call set_pixel
		
		next_draw:
			beq s1, s3, next_j_draw		# if (y == y max) increment x
			addi s1, s1, 1				# else increment y
			br loop_draw
			next_j_draw:
				beq s0, s2, end_draw	# if (x == x max) end loop
				add s1, zero, zero		# restart y
				addi s0, s0, 1			# else increment x
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
	addi sp,sp,-20      	# pushing return adress and saved registers on the stack
	stw ra, 0(sp)            
	stw s3, 4(sp)
	stw s1, 8(sp)       	# stack = top -> ra/s0/s1/s2
	stw s2, 12(sp)
    stw s4, 16(sp)

	ldw s1, T_X(zero)  		# s1 = x position of the anchor point
	ldw s2, T_Y(zero)  		# s2 = y position of the anchor point
	add a2,a0,zero     		# a2 stores the p value of the GSA
	add a0, s1, zero   		# setting the arguments for set_gsa
	add a1, s2, zero

	call set_gsa       		# setting the anchor point in the gsa

	ldw t0, T_type(zero)
	ldw t1, T_orientation(zero)
	slli t0,t0,2
	add t0,t0,t1     
	slli t0,t0,2         	# t0 = (T_type*4 + T_orientation) << 2
    ldw s3, DRAW_Ax(t0)  	# s3 stores the pointer to the offset array x
    ldw s4, DRAW_Ay(t0)  	# s4 stores the pointer to the offset array y
	addi t3,s3,12 			# loop limit

	# this loop sets the gsa for the surrouding point around the anchor point
	mini_loop:                               
		beq s3,t3, return_time
		ldw t1, 0(s3) 		# offset in array for x axis
		ldw t2, 0(s4) 		# offset in array for y axis
        
		add a0, s1, t1      # ao = x + offset
		add a1, s2,t2       # a1 = y + offset

		addi sp,sp,-4
		stw t3,0(sp)		#pushing t3 on the stack because it's the loop limit

		call set_gsa        # set the surrounding gsas around the anchor gsa

		ldw t3,0(sp)
		addi sp,sp,4		#popping t3 off the stack

		addi s3,s3,4
        addi s4,s4,4
		br mini_loop


	return_time:
        ldw s4,16(sp)
		ldw s2,12(sp)
		ldw s1, 8(sp)
		ldw s3, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,20
	ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
	loop:
		ldw t0, RANDOM_NUM(zero)
		andi t0,t0,0x7
		cmpgei t1, t0, 5
		bne t1,zero, loop

		stw t0,T_type(zero) 		# random tetromino shape
		addi t0,zero,6
		addi t1,zero,1
		addi t2, zero, N
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
	addi sp,sp,-20      	# pushing return adress and saved registers on the stack
	stw ra, 0(sp)            
	stw s3, 4(sp)
	stw s1, 8(sp)       	# stack = top -> ra/s3/s0/s1/s2
	stw s2, 12(sp)
    stw s4, 16(sp)

    add s1, zero, a0	 	# s1 stores the collision we are interested in
	ldw t0, T_type(zero)
	ldw t1, T_orientation(zero)
	slli t0,t0,2
	add t0,t0,t1     
	slli t0,t0,2         	# t0 = (T_type*4 + T_orientation) << 2
    ldw s3, DRAW_Ax(t0)  	# s3 stores the pointer to the offset array for x
    ldw s4, DRAW_Ay(t0)  	# s4 stores the pointer to the offset array for y
	
	# checking in which collison we are
	which_collision_check:
		addi t0, zero, W_COL
		addi t1,zero, E_COL
		addi t2,zero, So_COL
		addi t3,zero, OVERLAP
		beq s1,t0,west
		beq s1,t1,east
		beq s1,t2,south
		beq s1,t3,overlap
		br no_collision



	# in_gsa and get_gsa only use register t0 and t1, we are safe to use the others
    overlap:
		ldw a0, T_X(zero)				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		call in_gsa
		bne v0,zero,collision_exist		# would be out of gsa so collision

		ldw a0, T_X(zero)				# putting back the arguments because they are caller-saved
 		ldw a1, T_Y(zero) 			
		call get_gsa
		bne v0,zero,collision_exist

		addi t3,s3,12					# loop limit for iterating over tetrominoes

	loop_overlap:                       # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		
		addi sp,sp,-4
		stw t3,0(sp)					#pushing t3 on the stack because it's the loop limit

		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		call in_gsa
		bne  v0,zero,collision_exist    # would be out of gsa so collision


		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		
		call get_gsa
		bne v0,zero,collision_exist     # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4

		ldw t3,0(sp)
		addi sp,sp,4		#popping t3 off the stack

		br loop_overlap



	west:
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a0,a0,-1       			# decrementing the x coordinate  because W_COL
		call in_gsa
		bne v0,zero,collision_exist     # would be out of gsa so collision

		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a0,a0,-1       			# decrementing the x coordinate  because W_COL

		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 					# loop limit for iterating over tetrominoes

	loop_west:                          # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4) 					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero)		 		# anchor y coordinate

		addi sp,sp,-4
		stw t3,0(sp)					#pushing t3 on the stack because it's the loop limit

		add a0, a0, t1       	 		# ao = x + offset
		add a1, a1,t2        	 		# a1 = y + offset
		addi a0,a0,-1           		# decrementing the y coordinate  because W_COL
		call in_gsa
		bne  v0,zero,collision_exist    # would be out of gsa so collision

		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		addi a0,a0,-1           		# decrementing the y coordinate  because W_COL

		call get_gsa
		bne v0,zero,collision_exist     # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4

		ldw t3,0(sp)
		addi sp,sp,4		#popping t3 off the stack

		br loop_west



	east:
		ldw a0, T_X(zero) 				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a0,a0,1       				# incrementing the x coordinate  because E_COL
		call in_gsa
		bne v0,zero,collision_exist     # would be out of gsa so collision

		ldw a0, T_X(zero) 				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a0,a0,1       				# incrementing the x coordinate  because E_COL
		
		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 					# loop limit for iterating over tetrominoes

	loop_east:                          # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)	 				# offset in array for y axis
		ldw a0, T_X(zero)	 			# anchor x coordinate
 		ldw a1, T_Y(zero)		 		# anchor y coordinate

		addi sp,sp,-4
		stw t3,0(sp)					#pushing t3 on the stack because it's the loop limit

		add a0, a0, t1        			# ao = x + offset
		add a1, a1,t2        	 		# a1 = y + offset
		addi a0,a0,1           			# incrementing the y coordinate  because E_COL
		call in_gsa
		bne  v0,zero,collision_exist    # would be out of gsa so collision

		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		addi a0,a0,1           	 		# incrementing the y coordinate  because E_COL


		call get_gsa
		bne v0,zero,collision_exist     # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4

		ldw t3,0(sp)
		addi sp,sp,4		#popping t3 off the stack

		br loop_east


	south:
		ldw a0, T_X(zero) 				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a1,a1,1       				# incrementing the y coordinate  because SO_COL
		call in_gsa
		bne v0,zero,collision_exist     # would be out of gsa so collision

		ldw a0, T_X(zero) 				# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		addi a1,a1,1       				# incrementing the y coordinate  because SO_COL

		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 					# loop limit for iterating over tetrominoes

	loop_south:                         # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4) 					# offset in array for y axis
		ldw a0, T_X(zero) 				# anchor x coordinate
 		ldw a1, T_Y(zero)		 		# anchor y coordinate

		addi sp,sp,-4
		stw t3,0(sp)					#pushing t3 on the stack because it's the loop limit

		add a0, a0, t1        			# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		addi a1,a1,1           			# incrementing the y coordinate  because SO_COL
		call in_gsa
		bne  v0,zero,collision_exist    # would be out of gsa so collision

			ldw t1, 0(s3) 					# offset in array for x axis
		ldw t2, 0(s4)					# offset in array for y axis
		ldw a0, T_X(zero)		 		# anchor x coordinate
 		ldw a1, T_Y(zero) 				# anchor y coordinate
		add a0, a0, t1       		 	# ao = x + offset
		add a1, a1,t2         			# a1 = y + offset
		addi a1,a1,1           			# incrementing the y coordinate  because SO_COL

		call get_gsa
		bne v0,zero,collision_exist     # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4

		ldw t3,0(sp)
		addi sp,sp,4		#popping t3 off the stack

		br loop_south


	collision_exist:
		add v0,zero,s1 		# the collision exists so we return the input
        ldw s4,16(sp)
		ldw s2,12(sp)
		ldw s1, 8(sp)
		ldw s3, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,20
		ret

   no_collision:
    	ldw s4,16(sp)
		ldw s2,12(sp)
		ldw s1, 8(sp)
		ldw s3, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,20
        addi v0,zero,NONE  	# the collison doesn't exist so we return NONE
		ret



; END:detect_collision

; BEGIN:rotate_tetromino
rotate_tetromino:
# the idea is to decrement if left rotation else increment 
# the current orientation, and then masking the last 2 bits
	addi t4,zero, rotL
	ldw t5, T_orientation(zero)
	andi t5,t5,0x3
	beq a0,t4,left
	right:
	addi t5,t5,1
	br back
	left:
	addi t5,t5,-1
	back:
	andi t5,t5,0x3
	stw t5, T_orientation(zero)
	ret
; END:rotate_tetromino

; BEGIN:act
act:
	addi sp,sp,-16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)  		# stack looks like : top -> ra/s0/s1/s2

	addi t0,zero,moveL
	addi t1, zero,rotL
	addi t2,zero,reset
	addi t3, zero, rotR
	addi t4,zero, moveR
	addi t5,zero, moveD
	
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
	beq s0,v0,unchanged
	ldw t1,T_X(zero)
	addi t1,t1,1
	stw t1,T_X(zero)
	br changed

downmove:
	addi s0,zero, So_COL
	addi a0, zero, So_COL
	call detect_collision
	beq s0,v0,unchanged
	ldw t1,T_Y(zero)
	addi t1,t1,1
	stw t1,T_Y(zero)
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
	addi t1,zero,4
	ldw	 t0,BUTTONS(t1)		#to stores edgecapture (edgecapture is at BUTTON+4)
	andi t0,t0,31			#we want only the last 5 bits
	add t4,zero,zero		#bit counter 
	
tom_loop:
	beq t0,zero,no_input_back
	andi t1,t0,1
	bne t1,zero,yes_input_back
	srli t0,t0,1
	addi t4,t4,1
	br tom_loop

yes_input_back:
	addi v0,zero,1
	sll  v0,v0,t4
	ret

no_input_back:
	add v0,zero,zero
	ret


; END:get_input

; BEGIN:detect_full_line
detect_full_line:
	addi sp, sp, -16
	stw s0, 0(sp)
	stw s1, 4(sp)
	stw s2, 8(sp)
	stw ra, 12(sp)
	addi s0, zero, 1
	addi s1, zero, 7
	addi s2, zero, 11
	
	loop_full_line:
		add a0, zero, s2
		add a1, zero, s1
		call get_gsa
		and s0, s0, v0
		addi s2, s2, -1
		bge s2, zero, loop_full_line
		
		next_y_full_line:
			bne s0, zero, happy_ending
			addi s0, zero, 1
			addi s2, zero, 11
			addi s1, s1, -1
			bge s1, zero, loop_full_line

		epic_loss:
			addi v0, zero, 8
			ldw s0, 0(sp)
			ldw s1, 4(sp)
			ldw s2, 8(sp)
			ldw ra, 12(sp)
			addi sp, sp, 16

			ret
		happy_ending:
			add v0, zero, s1
			ldw s0, 0(sp)
			ldw s1, 4(sp)
			ldw s2, 8(sp)
			ldw ra, 12(sp)
			addi sp, sp, 16

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
	beq a0,t0, back_to_the_game   # if a0 = 8 then do nothing 

	add s0,zero,a0			# s0 stores the y coordinate of the line to removve		
	addi  s2,zero,4         # blink counter
blink:
	addi s1,zero,11
	
off:
	add a0,s0,zero			# x coordinate
	add a1,s1,zero			# y coordinate
	add a2,zero,zero		# set the line off
	
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
	add a0,s0,zero			# x coordinate
	add a1,s1,zero			# y coordinate
	addi a2,zero,1			# set the line on
	
	call set_gsa
	
	addi s1,s1,-1			
	cmplt t7,s1,zero	
	bne t7,zero,on

	call draw_gsa
	call wait
	addi s2,s2,-1
	br blink

make_lines_go_down:
	add s2, zero,s0				#s2 stores the current y coordinate of the line to modifiy
	add s1,zero,zero			#s1 stores the current x coordinate of the gsa to be modified
	addi s3,zero,12				#s3 is the loop limit on the x coordinate
	addi s4,zero,7				#s4 is the loop limit on the y coordinate



	
 move_line_down :
	beq s2,s4,back_to_the_game
	add s1,zero,zero   # reset the x coordinate

	loop_over_gsa:
		beq s1,s3,cont2
		add a0,s1,zero  #a0 = x coordinate
		addi a1,s2,1     #a1 = y + 1
		call get_gsa
		addi t0,t0,FALLING     
		beq v0,t0,cont1  # checking if FALLING
		add a0,s1,zero  #a0 = x coordinate
		add a1,s2,zero     #a1 = y
		add a2,v0,zero    # a2 = element on top of (x,y)
		call set_gsa
	cont1: 
	addi s1,s1,1
	br loop_over_gsa
	cont2:
	addi s2,s2,1
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
	addi t1, zero, 999
	addi t0, t0, 1

	bge t0, t1, ceiling		# if (SCORE+1 ≥ 999) SCORE = 999
	stw t0, SCORE(zero)
	ret

	ceiling:
	stw t1, SCORE(zero)		
	ret
; END:increment_score

; BEGIN:display_score
display_score:
	ldw t0, SCORE(zero)
	add t1, t0, zero		
	add t2, t0, zero		# t0 ... t2 = SCORE
	add t3, zero, zero		# t3 = digit 1
	add t4, zero, zero		# t4 = digit 2
	addi t5, zero, 9		# t5 = i

	addi t5, zero, 10
	addi t6, zero, 100
	
	get_digits:
		isolate_d0:
			blt t0, t5, isolate_d1
			sub t0, t0, t5				# t0 -= 10
			br isolate_d0
		isolate_d1:
			blt t1, t6, isolate_d2
			sub t1, t1, t6				# t1 -= 100
			br isolate_d1
		isolate_d2:
			sub t1, t1, t0				# t1 = t1 - t0
			sub t2, t2, t0			
			sub t2, t2, t1				# t2 = t2 - t1 - t0
		
		compute_d1:
			blt zero, t1, compute_d2
			addi t1, t1, -10				# t3 = nbr times 10 can be retrieved from t1
			addi t3, t3, 1
			br compute_d1
		compute_d2:
			blt zero, t2, digits_assign
			addi t2, t2, -100
			addi t4, t4, 1					# t4 = nbr times 100 can be retrieved from t2
			br compute_d2
	
	digits_assign:
		blt t5, zero, end_display_score		# end if i < 0
		slli t7, t5, 2
		ldw t6, font_data(t7)				# t6 = font_data(i*4)

		bne t0, t5, assign_d1				# if (t0 == i)
		stw t6, SEVEN_SEGS+12(zero)			# SEVEN_SEGS[3] = i
		assign_d1:
		bne t3, t5, assign_d2				# if (t3 == i)
		stw t6, SEVEN_SEGS+8(zero)			# SEVEN_SEGS[2] = i
		assign_d2:
		bne t4, t5, next_assign				# id (t4 == i)
		stw t6, SEVEN_SEGS+4(zero)			# SEVEN_SEGS[1] = i
		
		next_assign:
		addi t5, t5, -1						
		br digits_assign			
		
	end_display_score:
		ldw t6, font_data(zero)
		stw t6, SEVEN_SEGS(zero)			# SEVEN_SEGS[0] = 0
		ret
		
; END:display_score

; BEGIN:reset_game
reset_game:
	addi sp,sp,-24
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp) 


	stw zero,SCORE(zero) # reset the score to zero


	# resetting the entire gsa

	addi s0,zero,-1 #loop limit for both loops
	addi s1,zero,11 #s1 = current x coordinate 
	addi s2,zero,7  # s2 = current y coordinate

	loop_over_y:
		beq s2,s0, put_tetromino
		addi s1,zero,11

	loop_over_x:
		beq s1,s0, conty
		add a0,s1,zero   
		add a1,s2,zero			# setting the arguments for set_gsa
		add a2,zero,zero 
		call set_gsa
		addi s1,s1,-1
		br loop_over_x

	conty:
	addi s2,s2,-1
	br loop_over_y

	put_tetromino:
	call generate_tetromino
	


	ldw s4, 20(sp)
	ldw s3, 16(sp)
	ldw s2, 12(sp)
	ldw s1, 8(sp)
	ldw s0, 4(sp)
	ldw ra, 0(sp)
	addi sp,sp,24	
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
