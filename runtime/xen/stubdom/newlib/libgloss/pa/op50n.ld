OUTPUT_ARCH(hppa)
ENTRY("$START$")
STARTUP(crt0.o)
GROUP(-lc -lop50n -lgcc)
SEARCH_DIR(.)

MEMORY
{
  ram (rwx) : ORIGIN = 0x40000, LENGTH = 0x100000
}

SECTIONS
{
  .text :
  {
    CREATE_OBJECT_SYMBOLS
    *(.PARISC.stubs)
    *(.text)
     etext  =  . ;
     _etext  =  . ;
     __CTOR_LIST__ = . ;
     LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
    *(.ctors)
     LONG(0)
     __CTOR_END__ = . ;
     __DTOR_LIST__ = . ;
     LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
    *(.dtors)
     LONG(0)
     __DTOR_END__ = . ;
    *(.lit)
    *(.shdata)
    $global$ = ALIGN(4) ;
    . += 4;
  } > ram

  .data : {
    *(.data)
    CONSTRUCTORS
    edata  =  . ;
    _edata  =  . ;
  } > ram

  .bss : {
    _bss_start = ALIGN(4) ;
    *(.bss)
    *(COMMON)
    _stack = ALIGN(64) ;	/* Stack grows up on the PA!!! */
    . += 0x2000 ;
    end = . ;
    _end = . ;
  } > ram

}
