
	.section .text.startup

	.globl boot

	
	.org 0x100

boot:
	l.xor   r0,r0,r0

	l.jal	main
	l.nop
1:	
	l.j     1b
	l.nop


	.end

