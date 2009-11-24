/* must compile with -nostdlib option */
OUTPUT_FORMAT("a.out-sunos-big", "a.out-sunos-big",
              "a.out-sparc-little")
OUTPUT_ARCH(sparc)
SEARCH_DIR(/usr/local/sparclet-aout/lib)
PROVIDE (__stack = 0);
ENTRY (start)
STARTUP (crt0-701.o)
GROUP (libsplet701.a libc.a libgcc.a)
SECTIONS
{
  /* Sparcmon likes to load programs starting at this address. */
  . = 0x12010000;
  .text :
  {
    CREATE_OBJECT_SYMBOLS
    *(.text)
    /* The next six sections are for SunOS dynamic linking.  The order
       is important.  */
    *(.dynrel)  
    *(.hash)
    *(.dynsym)
    *(.dynstr)
    *(.rules)
    *(.need)
    _etext = .;
    __etext = .;
  }
  .data :
  {
    /* The first three sections are for SunOS dynamic linking.  */
    *(.dynamic)
    *(.got)
    *(.plt)
    *(.data)
    *(.linux-dynamic) /* For Linux dynamic linking.  */
    CONSTRUCTORS
    _edata  =  .;
    __edata  =  .;
  }
  .bss :
  {
    __bss_start = .;
   *(.bss)
   *(COMMON)
   _end = ALIGN(4) ;
   __end = ALIGN(4) ;
  }
  /* This is the value that Sparcmon assigns to the SP at reset, minus 4K. */
  PROVIDE(___stack = 0x123ef000);
  PROVIDE(__stack = 0x123ef000);
  /* Provide 4K area for copying the trap vectors from ROM to RAM.  */
  PROVIDE(___trap_vectors = 0x123f0000);
  PROVIDE(__trap_vectors = 0x123f0000);
}
