; BEGIN:wait
wait:
	addi a0, zero, 0x1
	slli a0, a0, 20				#sets the 20th bit to 1 in order to have 2^20

	call count_down				#count until 2^20
	
	ret
; END:wait

; BEGIN:helper
count_down:
	addi a0, a0, -1 			#decrement argument by 1
	bne a0, zero, count_down	#compare a0 to 0 and restart if not equal

	ret
; END:helper