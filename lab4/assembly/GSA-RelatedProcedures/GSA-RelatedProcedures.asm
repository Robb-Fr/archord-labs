; BEGIN:get_gsa
get_gsa:
slli t1,a0,3     #t1 stores the value from 0 to 95, here i do t1 = x*8
add t1,t1,a1     # here i get t1 = x*8 + y
slli t1,t1,2     # t1 is shifted by 2 to get a mutliple of 4
ldw v0, GSA(t1)  # loading the correct GSA square in v0
ret
; END:get_gsa

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

; BEGIN:set_gsa
set_gsa:
slli t1,a0,3     # t1 stores the value between 0 and 95, here i do t1 = x*8
add t1,t1,a1     # i do t1 = x*8 + y
slli t1,t1,2      # shifting t1 by 2 to get a multiple of 4

stw a2, GSA(t1)   # storing p taking value in (NOTHING,PLACED,FALLING) in the correct GSA square
ret
; END:set_gsa
