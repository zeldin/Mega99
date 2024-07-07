
	.section .text.startup

	.globl boot

	
	.org 0x10

boot:
	l.xor   r0,r0,r0
	l.ori	r1,r0,lo(__stack)
	l.ori	r3,r0,lo(__bss_start)
	l.ori	r4,r0,lo(_end)
1:
	l.sw    0(r3),r0
	l.sfltu r3,r4
	l.bf	1b
	l.addi  r3,r3,4
	l.jal	main
	l.nop
1:	
	l.j     1b
	l.nop


	.end

