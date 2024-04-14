
	.text

	.globl boot

	
	.org 0x100

boot:
	l.xor   r0,r0,r0

	l.lwz   r1,0(r0)
	l.movhi r2,0x0102
	l.ori   r2,r2,0x0304
	l.add   r1,r1,r2
	l.sw    0(r0),r1

	l.movhi r1,0x2a3f
	l.ori   r1,r1,0x2b3a
	l.sw    32(r0),r1
	l.sb    37(r0),r1

	l.ori   r1,r0,11
	l.sb    0x4007(r0),r1

1:	
	l.j     1b
	l.nop


	.end

