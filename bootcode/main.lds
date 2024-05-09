SECTIONS {
        /DISCARD/ : {
                *(.comment)
                *(.debug*)
        }
        .text : {
                . = 0x000000;
                *(.text.startup);
                *(.text*);
        }
	.rodata : { *(.rodata* .gnu.linkonce.r.*) }
	.data :  { *(.data* .gnu.linkonce.d.*) }
	. = ALIGN(4);
	. = ALIGN(ALIGNOF(NEXT_SECTION));
        __bss_start = .;
	.sbss : {
		*(.sbss* .gnu.linkonce.sb.*)
		*(.scommon)
	}
	.bss : {
		*(.bss* .gnu.linkonce.b.*)
		*(COMMON)
	}
	. = ALIGN(4);
	_end = .; PROVIDE (end = .);
	ASSERT(end <= __stack - 1024, "Less than 1k left for stack!")
}
