; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
	ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	addi t0, zero, 15  #creating the mask
	slli t0,t0,2
	and  t1,a0, t0     #forcing last two bits of arguments at zero to get a multiple of 4(0 or 4 or 8)
	ldw t2, LEDS(t1)   # loading correct word (t1 = 0,4,8)

	addi t0,zero, 15   # creating another mask
	srli t0,t0,2
	and t3, a0, t0    # t3 is the offset 0,1,2,3 to be used to find the correct bit to set at postion (y + offset*8)

	addi t4,zero,1    # t4 will be the mask for the correct bit
	sll  t4,t4, a1    # t4 has now been shifted by y and will be then shifted by offset*8

	slli t3,t3,3      # offset*8
	sll t4,t4,t3      # shfiting t4 by offset*8         
	or t2,t2,t4
	stw t2,LEDS(t1)
	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi a0, zero, 0x1
	slli a0, a0, 20				#sets the 20th bit to 1 in order to have 2^20

	count_down:
		addi a0, a0, -1 		#decrement argument by 1
		bne a0, zero, count_down	#compare a0 to 0 and restart if not equal

	ret
; END:wait
