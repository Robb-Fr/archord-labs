.equ LEDS, 0x2000
.equ GSA, 0x1014

; BEGIN:draw_gsa
draw_gsa:
	add t0, zero, zero		#LED_loop counter (0->2)
	add t1, zero, zero		#WORD_loop counter (0->31)
	addi t2, zero, 3		#last value of LED_loop counter
	addi t3, zero, 32		#last value of WORD_loop counter
	#t4 stores current GSA address
	#t5 stores current GSA word
	#t6 stores the mask for LED word
	#t7 stores the current LED word
	LED_loop:
		ldw t7, LEDS(t0)	#prepare the word to store

		WORD_loop:
			slli t4, t0, 5			#GSA address = 32*LED_loop counter
			add t4, t4, t1			#GSA_address = GSA_address + WORD_loop counter
			slli t4, t4, 2			#Get valid address

			ldw t5, GSA(t4)			#current GSA word load

			cmpgei t5, t5, 1		# t5 == (falling||placed) ? 1 : 0
			sll t6, t5, t1			#setting the mask
			
			or t7, t7, t6			#apply mask
			
			addi t1, t1, 1			#update counter
			bne t1,t3, WORD_loop	#loop if counter ≠ max value

			stw t7, LEDS(t0)		#store the word
			add t1, zero, zero		#reinitialize counter
			addi t0, t0, 1			#update counter
		
		bne t0, t2, LED_loop	#loop if counter ≠ max value

	return:
	ret
; END:draw_gsa