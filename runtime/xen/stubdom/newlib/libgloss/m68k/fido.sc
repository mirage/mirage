SRAM_ORIGIN=0x03000000
SRAM_LENGTH=0x00100000

# HEAPEND must be in the same memory region as DATA.  STACK should be
# above HEAPEND, also in the same region, for configurations which
# need __stack.

case $MODE in
    rom)
	CRT0=rom
	TEXT=rom
	DATA=sram
	DATALOAD="rom"
	STACK=0x030ffffc
	HEAPEND=0x03080000
	;;
    sram)
	CRT0=ram
	TEXT=sram
	DATA=sdram
	STACK=0x021ffffc
	HEAPEND=0x02180000
	# Leave the rest of SDRAM for manual use.
	;;
    sdram)
	CRT0=ram
	TEXT=sdram
	DATA=sdram
	STACK=0x021ffffc
	HEAPEND=0x02180000
	# Leave the rest of SDRAM for manual use.
	;;
    redboot)
	CRT0=redboot
	# We need to avoid the area used by RedBoot
	SRAM_ORIGIN=0x3080000
	SRAM_LENGTH=0x80000
	# Put code for RedBoot apps in SRAM, since the fido1100 has
	# trouble running code from SDRAM.
	TEXT=sram
	DATA=sdram
	STACK=0
	HEAPEND=0x027f0000
	;;
    *)
	ERROR
	;;
esac

cat <<EOF
/*
 * Setup the memory map of the Innovasic SBC 
 * stack grows down from high memory.
 *
 * The memory map for the ROM model looks like this:
 *
 * +--------------------+ <-address 0 in Flash
 * | .vector_table      |
 * +--------------------+ <- low memory
 * | .text              |
 * |        _etext      |
 * |        ctor list   | the ctor and dtor lists are for
 * |        dtor list   | C++ support
 * +--------------------+
 * | DCACHE_CODE        | code to be loaded into DCACHE
 * |     _dcache_start  |
 * |     _dcache_end    |
 * +--------------------+
 * | .data              | initialized data goes here
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * +--------------------+ <- The beginning of the SRAM area
 * | .data              | a wriable copy of data goes here.
 * |        _edata      |
 * +--------------------+
 * | .bss               |
 * |        __bss_start | start of bss, cleared by crt0
 * |        _end        | start of heap, used by sbrk()
 * |        _heapend    |    End   of heap, used by sbrk()
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * |        __stack     | top of stack
 * +--------------------+
 *
 *
 * The memory map for the RAM model looks like this:
 *
 * +--------------------+ <- The beginning of the SRAM or SDRAM area.
 * | .vector_table      |
 * +--------------------+ <- low memory
 * | .text              |
 * |        _etext      |
 * |        ctor list   | the ctor and dtor lists are for
 * |        dtor list   | C++ support
 * +--------------------+
 * | DCACHE_CODE        | code to be loaded into DCACHE
 * |     _dcache_start  |
 * |     _dcache_end    |
 * +--------------------+
 * | .data              | initialized data goes here
 * |        _edata      |
 * +--------------------+
 * | .bss               |
 * |        __bss_start | start of bss, cleared by crt0
 * |        _end        | start of heap, used by sbrk()
 * |        _heapend    |    End   of heap, used by sbrk()
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * |        __stack     | top of stack
 * +--------------------+
 */

STARTUP(fido-${CRT0}-crt0.o)
OUTPUT_ARCH(m68k)
ENTRY(_start);
GROUP(-l${IO} -lfido -lc -lgcc)

MEMORY {
  /* Flash ROM.  */
  rom (rx)      : ORIGIN = 0x0000000, LENGTH = 0x800000
  /* Internal SRAM.  */
  int_ram (rwx) : ORIGIN = 0x1000000, LENGTH = 0x6000
  /* External SDRAM.  */
  sdram (rwx)   : ORIGIN = 0x2000000, LENGTH = 0x800000
  /* External SRAM.  */
  sram (rwx)     : ORIGIN = ${SRAM_ORIGIN}, LENGTH = ${SRAM_LENGTH}
}

SECTIONS {
  /* The interrupt vector is placed at the beginning of ${TEXT},
     as required at reset.  */
  .vector_table : {
    *(.vector_table)
  } > ${TEXT}

  /* Text section.  */
  .text :
  {
    *(.text .text.*)
    *(.gnu.linkonce.t.*)

    . = ALIGN(0x4);
    /* These are for running static constructors and destructors under ELF.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*crtend.o(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*crtend.o(.dtors))

    . = ALIGN(0x4);
    KEEP (*crtbegin.o(.jcr))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .jcr))
    KEEP (*crtend.o(.jcr))

    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.gcc_except_table) 
    *(.eh_frame)

    . = ALIGN(0x2);
    _init = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.init)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    _fini = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.fini)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */
    . = ALIGN(0x800);   /* align to a 2K dcache boundary */
    _dcache_start = .;
    *(DCACHE_CODE)
    _dcache_end = .;
    _etext = .;
    *(.lit)
    . = ALIGN(0x4);
    __start_romdata = .;
  } > ${TEXT}

  /* Initialized data section.  */
  .data :
  {
    _data = .;
    *(.got.plt) *(.got)
    *(.shdata);
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    _edata_cksum = .;
    *(checksum);
    _edata = .;
  } > ${DATA} ${DATALOAD:+AT>} ${DATALOAD}

  /* Zero-initialized data.  */ 
  .bss :
  {
    . = ALIGN(0x4);
    __bss_start = . ;
    *(.shbss)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    _end =  ALIGN (0x8);
    __end = _end;
  } > ${DATA}

  /* Specially designated data is placed in the internal RAM.  */
  fast_memory :
  {
    . = ALIGN(0x4);
    __fast_start = .;
    *(FAST_RAM)
    __fast_stop = .;
  } > int_ram
}

PROVIDE (__stack = ${STACK});

PROVIDE (_heapend = ${HEAPEND});
EOF
