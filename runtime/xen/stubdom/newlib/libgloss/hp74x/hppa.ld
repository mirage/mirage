STARTUP(crt0-hppa.o)
OUTPUT_ARCH(hppa)
/*** INPUT(hppa.o) ***/
SEARCH_DIR(.)
__DYNAMIC  =  0;

/*
 * Setup the memory map of the MC68ec0x0 Board (IDP)
 * stack grows up towards high memory. This works for
 * both the rom68k and the mon68k monitors.
 */
MEMORY
{
  ram (rwx) : ORIGIN = 0x10000, LENGTH = 32M
}

/*
 * stick everything in ram (of course)
 */
SECTIONS
{
  .text :
  {
    CREATE_OBJECT_SYMBOLS
    *(.text)
     etext  =  .;
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
  }  > ram
  .shbss SIZEOF(.text) + ADDR(.text) :	{
    *(.shbss)
  } 
  .data  : {
    *(.data)
    CONSTRUCTORS
    _edata  =  .;
  } > ram

  .bss SIZEOF(.data) + ADDR(.data) :
  {
   _bss_start = ALIGN(0x8);
   *(.bss)
   *(COMMON)
      _bss_end = ALIGN(0x8);
  }
  .stab  0 (NOLOAD) : 
  {
    [ .stab ]
  }
  .stabstr  0 (NOLOAD) :
  {
    [ .stabstr ]
  }
}
