/*
 *uncomment this if you want the linker to output srecords.
OUTPUT_FORMAT(srec)
 *
 */
STARTUP(traps.o)
INPUT(sim-crt0.o)
OUTPUT_ARCH(sparc)
SEARCH_DIR(.)
__DYNAMIC  =  0;
GROUP(-lc -lsim -lgcc)

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
_RAM_SIZE = 2M;

_RAM_START = 0x02020000;
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
/*
MEMORY
{
  rom       : ORIGIN = 0x00000000, LENGTH = 4M
  ram (rwx) : ORIGIN = 0x02000000, LENGTH = 2M
}
*/

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
  .text 0x02000000 :  {
    stext = .;
    _stext = .;
    *(.text)
     _etext  =  .;
    __CTOR_LIST__ = .;
    LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
    *(.ctors)
    LONG(0)
    __CTOR_END__ = .;
    __DTOR_LIST__ = .;
    LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
    *(.dtors)
    LONG(0)
    __DTOR_END__ = .;
    *(.lit)
    *(.shdata)
    _endtext = .;
  }  > ram
  .shbss SIZEOF(.text) + ADDR(.text) :	{
    *(.shbss)
  } 
  .talias :	 { }  > ram
  .data : {
    sdata  =  .;
    _sdata  =  .;
    *(.data)
    edata  =  .;
    _edata  =  .;
  } > ram
  .bss SIZEOF(.data) + ADDR(.data) :
  {
   sbss = . ;
   _sbss = . ;
   __bss_start = ALIGN(0x8);
   *(.bss)
   *(COMMON)
   end = ALIGN(0x8);
   _end = ALIGN(0x8);
   __end = ALIGN(0x8);
   ebss = .;
   _ebss = .;
  }
  .mstack  : { }  > ram
  .rstack  : { }  > ram
  .stab  0 (NOLOAD) : 
  {
    [ .stab ]
  }
  .stabstr  0 (NOLOAD) :
  {
    [ .stabstr ]
  }
}
