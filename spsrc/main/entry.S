
	.section .text.startup

	.globl start

	
start:
	l.xor   r0,r0,r0
	l.movhi r1,hi(__stack_end)
	l.ori	r1,r1,lo(__stack_end)
	l.movhi r3,hi(__bss_start)
	l.ori	r3,r3,lo(__bss_start)
	l.movhi r4,hi(_end)
	l.ori	r4,r4,lo(_end)
1:
	l.sw    0(r3),r0
	l.sfltu r3,r4
	l.bf	1b
	l.addi  r3,r3,4

	l.or	r2, r0, r0
	l.or	r3, r0, r0
	l.or	r4, r0, r0
	l.or	r5, r0, r0
	l.jal	main
	l.nop
1:	
	l.j     1b
	l.nop


	.bss

	.align 4

__stack_start:	
	.ds.b	0x10000
__stack_end:

	.end
