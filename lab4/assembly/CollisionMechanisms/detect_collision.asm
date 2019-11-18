; BEGIN:detect_collision
detect_collision:
# the idea is to get the current tetromino coordinates via T_type and T_orientation which gives us the index in DRAW_Ax and DRAW_Ay
# then if we have a SO_COl, we increment every y coordinate, we check for each if in_gsa and then get_gsa and check if is 1 or not
# for W_COl, we decrement every x coordinate
# for E_COL we increment every x coordinate
# for OVERLAP, we directly check the current coordinates
# for NONE, output NONE
	addi sp,sp,-20      #pushing return adress and saved registers on the stack
	stw ra, 0(sp)            
	stw s3, 4(sp)
	stw s1, 8(sp)       # stack = top -> ra/s3/s0/s1/s2
	stw s2, 12(sp)
    stw s4, 16(sp)

    add s1, zero, a0 #  s1 stores the collision we are interested in
	ldw t0, T_type(zero)
	ldw t1, T_orientation(zero)
	slli t0,t0,2
	add t0,t0,t1     
	slli t0,t0,2         # s0 = (T_type*4 + T_orientation) << 2
    ldw s3, DRAW_Ax(t0)  # s3 stores the pointer to the offset array for x
    ldw s4, DRAW_Ay(t0)  # s4 stores the pointer to the offset array for y
	
	# checking in which collison we are
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
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate
		call in_gsa
		bne v0,zero,collision_exist      # would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 # loop limit for iterating over tetrominoes

	loop_overlap:                               # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) # offset in array for x axis
		ldw t2, 0(s4) # offset in array for y axis
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate

		add a0, a0, t1        # ao = x + offset
		add a1, a1,t2         # a1 = y + offset
		call in_gsa
		bne  v0,zero,collision_exist       #would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist        # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4
		br loop_overlap



	west:
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate
		addi a0,a0,-1       #decrementing the x coordinate  because W_COL
		call in_gsa
		bne v0,zero,collision_exist      # would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 # loop limit for iterating over tetrominoes

	loop_west:                               # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) # offset in array for x axis
		ldw t2, 0(s4) # offset in array for y axis
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate

		add a0, a0, t1        # ao = x + offset
		add a1, a1,t2         # a1 = y + offset
		addi a0,a0,-1           #decrementing the y coordinate  because W_COL
		call in_gsa
		bne  v0,zero,collision_exist       #would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist        # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4
		br loop_west



	east:
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate
		addi a0,a0,1       #incrementing the x coordinate  because E_COL
		call in_gsa
		bne v0,zero,collision_exist      # would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 # loop limit for iterating over tetrominoes

	loop_east:                               # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) # offset in array for x axis
		ldw t2, 0(s4) # offset in array for y axis
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate

		add a0, a0, t1        # ao = x + offset
		add a1, a1,t2         # a1 = y + offset
		addi a0,a0,1           #incrementing the y coordinate  because E_COL
		call in_gsa
		bne  v0,zero,collision_exist       #would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist        # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4
		br loop_east


	south:
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate
		addi a1,a1,1       #incrementing the y coordinate  because SO_COL
		call in_gsa
		bne v0,zero,collision_exist      # would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist
		addi t3,s3,12 # loop limit for iterating over tetrominoes

	loop_south:                               # this loop checks if the current tetrominoes moved in the given direction provock a collision
		beq s3,t3, no_collision
		ldw t1, 0(s3) # offset in array for x axis
		ldw t2, 0(s4) # offset in array for y axis
		ldw a0, T_X(zero) # anchor x coordinate
 		ldw a1, T_Y(zero) #anchor y coordinate

		add a0, a0, t1        # ao = x + offset
		add a1, a1,t2         # a1 = y + offset
		addi a1,a1,1           #incrementing the y coordinate  because SO_COL
		call in_gsa
		bne  v0,zero,collision_exist       #would be out of gsa so collision
		call get_gsa
		bne v0,zero,collision_exist        # the gsa is already occupied
		addi s3,s3,4
        addi s4,s4,4
		br loop_south


	collision_exist:
        ldw s4,16(sp)
		ldw s2,12(sp)
		ldw s1, 8(sp)
		ldw s3, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,20
		add v0,zero,s1 # the collision exists so we return the input
		ret

   no_collision:
    	ldw s4,16(sp)
		ldw s2,12(sp)
		ldw s1, 8(sp)
		ldw s3, 4(sp)
		ldw ra, 0(sp)
		addi sp,sp,20
        addi v0,zero,NONE  # the collison doesn't exist so we return NONE
		ret