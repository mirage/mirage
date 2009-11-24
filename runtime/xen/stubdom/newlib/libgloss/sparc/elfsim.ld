/* Linker script for running ELF programs in the Sparc simulator */

/* OUTPUT_FORMAT("elf32-sparc", "elf32-sparc", "elf32-sparcle") */
/* OUTPUT_FORMAT("elf32-sparc") */
OUTPUT_ARCH(sparc)
STARTUP(traps.o)
INPUT(erc32-crt0.o)
ENTRY(_trap_table)
GROUP(-lc -lerc32 -lgcc)  /*  -lerc32 used to be -lsim */

SEARCH_DIR(.)
/* Do we need any of these for elf?
   __DYNAMIC = 0;    */

/*
 * The memory map looks like this:
 * +--------------------+ <- low memory
 * | .text              |
 * |        _stext       |
 * |        _etext      |
 * |        ctor list   | the ctor and dtor lists are for
 * |        dtor list   | C++ support
 * |        _end_text   |
 * +--------------------+
 * | .data              | initialized data goes here
 * |        _sdata      |
 * |        _edata      |
 * +--------------------+
 * | .bss               |
 * |        __bss_start | start of bss, cleared by crt0
 * |        _end        | start of heap, used by sbrk()
 * +--------------------+
 * |    heap space      |
 * |        _ENDHEAP    |
 * |    stack space     | 
 * |        __stack     | top of stack
 * +--------------------+ <- high memory
 */

/*
 * User modifiable values:
 *
 * _CLOCK_SPEED               in Mhz (used to program the counter/timers)
 *
 * _PROM_SIZE                 size of PROM (permissible values are 4K, 8K, 16K
 *                               32K, 64K, 128K, 256K, and 512K)
 * _RAM_SIZE                  size of RAM (permissible values are 256K, 512K,
 *                               1MB, 2Mb, 4Mb, 8Mb, 16Mb, and 32Mb)
 *
 * These symbols are only used in assembler code, so they only need to
 * be listed once. They should always be refered to without SYM().
 */

_CLOCK_SPEED = 10;

_PROM_SIZE = 4M;
_RAM_SIZE = 256K;

_RAM_START = 0x02000000;
_RAM_END = _RAM_START + _RAM_SIZE;
_STACK_SIZE = (16 * 1024);
_PROM_START = 0x00000000;
_PROM_END = _PROM_START + _PROM_SIZE;


/*
 *  Base address of the on-CPU peripherals
 */

_ERC32_MEC = 0x01f80000;

/*
 * Setup the memory map for the SIS simulator.
 * stack grows up towards low memory. 
 */

MEMORY
{
  rom       : ORIGIN = 0x00000000, LENGTH = 4M
  ram (rwx) : ORIGIN = 0x02000000, LENGTH = 2M
}

__stack = _RAM_START + _RAM_SIZE - 4 * 16;
__trap_stack = (_RAM_START + _RAM_SIZE - 4 * 16) - _STACK_SIZE;

/*
 * All the symbols that might be accessed from C code need to be
 * listed twice, once with an additional underscore. aout format needs
 * and extra underscore, whereas coff & elf doesn't. This is to work
 * with both.
 */
SECTIONS
{
  .text      :
  {
    _stext = .;
    PROVIDE (stext = .);
    *(.text)
    _etext = .;
    PROVIDE (etext = .);

    /* For a.out.  */
    CONSTRUCTORS

    /* For ELF.  */
    __CTOR_LIST__ = .;
    LONG(-1)
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*crtend.o(.ctors))
    LONG(0)                                                    
    __CTOR_END__ = .;
    __DTOR_LIST__ = .;
    LONG(-1)
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*crtend.o(.dtors))
    LONG(0)              
    __DTOR_END__ = .;

    *(.init)
    *(.lit)
    *(.rodata)
    *(.shdata)
    __EH_FRAME_BEGIN__ = .;
    *(.eh_frame)
    *(.gnu.linkonce.t*)
    *(.gnu.linkonce.r*)
    *(.gcc_except_table)
    *(.fini)

    _endtext = .;
    PROVIDE(endtext = .);
  } > ram

  .shbss SIZEOF(.text) + ADDR(.text) :
  {
    *(.shbss)   
  }

  .talias : { }  > ram

  .data    :
  {
    _sdata  =  .;
    PROVIDE (sdata  =  .);
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d*)
    _edata  =  .;
    PROVIDE (edata  =  .);
  } > ram

  .bss SIZEOF(.data) + ADDR(.data) :
  {
    _sbss = . ;
    PROVIDE (sbss = . );
    __bss_start = ALIGN(0x8);
    *(.bss)
    *(COMMON)
    _ebss = .;
    PROVIDE (ebss = .);
    _end = ALIGN(0x8);    
    __end = ALIGN(0x8);
    PROVIDE (end = ALIGN(0x8));
  }

  /* Stabs debugging sections.  */
  .stab 0 : { *(.stab) }
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  .debug_ranges   0 : { *(.debug_ranges) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  /* These must appear regardless of  .  */
}
