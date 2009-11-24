OUTPUT_FORMAT("pei-mcore-big", "pei-mcore-big",
	  	           "pei-mcore-little")
GROUP(-lc -lcmb -lgcc)
ENTRY(_mainCRTStartup)
SECTIONS
{
  .text  0x2f000000 : 
  {
     *(.init)
    *(.text)
    *(SORT(.text$*))
    *(.glue_7t)
    *(.glue_7)
     ___CTOR_LIST__ = .; __CTOR_LIST__ = . ; 
			LONG (-1); *(.ctors); *(.ctor); LONG (0); 
     ___DTOR_LIST__ = .; __DTOR_LIST__ = . ; 
			LONG (-1); *(.dtors); *(.dtor);  LONG (0); 
     *(.fini)
    /* ??? Why is .gcc_exc here?  */
     *(.gcc_exc)
     etext = .;
    *(.gcc_except_table)
  }
  /* The Cygwin32 library uses a section to avoid copying certain data
     on fork.  This used to be named ".data".  The linker used
     to include this between __data_start__ and __data_end__, but that
     breaks building the cygwin32 dll.  Instead, we name the section
     ".data_cygwin_nocopy" and explictly include it after __data_end__. */
  .data BLOCK(__section_alignment__) : 
  {
    __data_start__ = . ;
    *(.data)
    *(.data2)
    *(SORT(.data$*))
    __data_end__ = . ;
    *(.data_cygwin_nocopy)
  }
  .bss BLOCK(__section_alignment__) :
  {
    __bss_start__ = . ;
    *(.bss)
    *(COMMON)
    __bss_end__ = . ;
  }
  .rdata BLOCK(__section_alignment__) :
  {
    *(.rdata)
    *(SORT(.rdata$*))
    *(.eh_frame)
  }
  .edata BLOCK(__section_alignment__) :
  {
    *(.edata)
  }
  /DISCARD/ :
  {
    *(.debug$S)
    *(.debug$T)
    *(.debug$F)
    *(.drectve)
  }
  .idata BLOCK(__section_alignment__) :
  {
    /* This cannot currently be handled with grouped sections.
	See pe.em:sort_sections.  */
    SORT(*)(.idata$2)
    SORT(*)(.idata$3)
    /* These zeroes mark the end of the import list.  */
    LONG (0); LONG (0); LONG (0); LONG (0); LONG (0);
    SORT(*)(.idata$4)
    SORT(*)(.idata$5)
    SORT(*)(.idata$6)
    SORT(*)(.idata$7)
  }
  .CRT BLOCK(__section_alignment__) :
  { 					
    *(SORT(.CRT$*))
  }
  .endjunk BLOCK(__section_alignment__) :
  {
    /* end is deprecated, don't use it */
     end = .;
     _end = .;
     __end__ = .;
  }
  .reloc BLOCK(__section_alignment__) :
  { 					
    *(.reloc)
  }
  .rsrc BLOCK(__section_alignment__) :
  { 					
    *(.rsrc)
    *(SORT(.rsrc$*))
  }
  .stab BLOCK(__section_alignment__) (NOLOAD) :
  {
    [ .stab ]
  }
  .stabstr BLOCK(__section_alignment__) (NOLOAD) :
  {
    [ .stabstr ]
  }
  .stack 0x2f0ffffc :
  {
    _stack = .;
    *(.stack)
  }
}
