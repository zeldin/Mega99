
	.text

	.globl boot

	
	.org 0x100

boot:
	l.xor   r0,r0,r0

	l.movhi r3,0x8000
	
	l.lwz   r4,0(r3)
	l.movhi r5,0x0102
	l.ori   r5,r5,0x0304
	l.add   r4,r4,r5
	l.sw    0(r3),r4

	l.movhi r4,0x2a3f
	l.ori   r4,r4,0x2b3a
	l.sw    32(r3),r1
	l.sb    37(r3),r1

	l.ori   r1,r0,11
	l.sb    0x4007(r3),r1

	l.ori   r5,r0,lo(2f)
	l.lbz   r4,2(r5)
	l.andi  r4,r4,0xdf
	l.sb    2(r5),r4
	l.lwz	r4,0(r5)
	l.sw	64(r3),r4
	l.lwz	r4,4(r5)
	l.sw	68(r3),r4

1:	
	l.j     1b
	l.nop

2:
	.ascii "Greetz!!"


	.end

