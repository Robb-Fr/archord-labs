; BEGIN:in_gsa
in_gsa:
	addi t0, zero, 12			#x must not get to this value
	addi t1, zero, 8			#y must not get to this value	

	blt a0, zero, flag_outside	#if x < 0
	bge a0, t0, flag_outside	#if x ≥ 12
	blt a1, zero, flag_outside	#if y < 0
	bge a1, t1, flag_outside	#if y ≥ 8

	br is_ok					#all tests passed

	flag_outside:
		addi v0, zero, 1		#set flag on
		br return
	is_ok:
		add v0, zero, zero		#set no flag
		br return

	return:
	ret
; END:in_gsa