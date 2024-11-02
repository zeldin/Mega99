
	.global _or1k_board_mem_base
	.global _or1k_board_mem_size
	.global _or1k_board_clk_freq
	.global _or1k_board_uart_base

_or1k_board_mem_base:	.long	0x40000000
_or1k_board_mem_size:	.long	0x00400000
_or1k_board_clk_freq:	.long	TICKS_PER_SEC
_or1k_board_uart_base:	.long	0x0

	.global _or1k_board_exit

_or1k_board_exit:
	l.nop 0xc
1:
	l.j 1b
	l.nop

	.global _or1k_board_init_early

_or1k_board_init_early:
	l.movhi r3,hi(0x40000000)
	l.mtspr r0,r3,0x000b
	l.jr r9
	l.nop

