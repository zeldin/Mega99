
	.section .text.startup

	.globl start

	
start:
	l.xor   r0,r0,r0
	l.movhi r1,hi(__stack_end)
	l.ori	r1,r1,lo(__stack_end)
	l.movhi r3,hi(start)
	l.mtspr r0,r3,0x000b
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


exception_main:
	l.jal	exception_handler
	l.nop
1:	
	l.j	1b
	l.nop
	

	.org	start+0x100

	l.j	exception_main
	l.ori	r3,r0,0x100

	.org	start+0x200

	l.j	exception_main
	l.ori	r3,r0,0x200
	
	.org	start+0x300

	l.j	exception_main
	l.ori	r3,r0,0x300
	
	.org	start+0x400

	l.j	exception_main
	l.ori	r3,r0,0x400
	
	.org	start+0x500

	l.j	exception_main
	l.ori	r3,r0,0x500
	
	.org	start+0x600

	l.j	exception_main
	l.ori	r3,r0,0x600
	
	.org	start+0x700

	l.j	exception_main
	l.ori	r3,r0,0x700
	
	.org	start+0x800

	l.j	exception_main
	l.ori	r3,r0,0x800
	
	.org	start+0x900

	l.j	exception_main
	l.ori	r3,r0,0x900
	
	.org	start+0xa00

	l.j	exception_main
	l.ori	r3,r0,0xa00
	
	.org	start+0xb00

	l.j	exception_main
	l.ori	r3,r0,0xb00
	
	.org	start+0xc00

	l.j	exception_main
	l.ori	r3,r0,0xc00

	.org	start+0xe00

	l.j	exception_main
	l.ori	r3,r0,0xe00



	.bss

	.align 4

__stack_start:	
	.ds.b	0x10000
__stack_end:

	.end
