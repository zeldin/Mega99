
	.text

	.globl boot

	
	.org 0x100

boot:	
	l.nop 0xabc9
	l.j   boot
	l.nop 0xfeed
	l.nop 0xface


	.end

