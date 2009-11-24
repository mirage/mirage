/* Example Linker Script for linking NS CRX elf32 files. */
OUTPUT_FORMAT("elf32-crx")
OUTPUT_ARCH(crx)

/* 
 The libh.a library includes various CR default handlers.
 The libsim.a library includes low-level functions, which
 are used as an interface to communicate with the simulator.
*/
GROUP(-lc -lsim -lh -lgcc)

/*
 The next line forces the entry point (_start in this script)
 to be entered in the output file as an undefined symbol.
 It is needed in case the entry point is not called explicitly
 (which is the usual case) AND is in an archive.
*/
EXTERN(_start)
ENTRY(_start)

/* Define memory regions */
MEMORY
{
  rom  : ORIGIN = 0x2,  LENGTH = 3M
  ram  : ORIGIN = 4M,   LENGTH = 10M
}

SECTIONS
{
  .init :
  { 
    __INIT_START = .; 
    KEEP (*(.init))
    __INIT_END = .; 
  } > rom

  .fini :
  { 
    __FINI_START = .; 
    KEEP (*(.fini))
    __FINI_END = .; 
  } > rom

  .jcr :
  { 
    KEEP (*(.jcr))
  } > rom

  .text : 
  { 
    __TEXT_START = .; 
    *(.text) *(.text.*) *(.gnu.linkonce.t.*) 
    __TEXT_END = .; 
  } > rom

  .rdata : 
  {
     __RDATA_START = .; 
     *(.rdata_4) *(.rdata_2) *(.rdata_1) *(.rdata.*) *(.gnu.linkonce.r.*) 
     __RDATA_END = .; 
  } > rom

  .ctor ALIGN(4) : 
  { 
    __CTOR_START = .; 
    KEEP (*crtbegin*.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend*.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
    __CTOR_END = .; 
  } > rom

  .dtor ALIGN(4) : 
  { 
    __DTOR_START = .; 
    KEEP (*crtbegin*.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend*.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
    __DTOR_END = .; 
  } > rom

  .data : 
  {
    __DATA_START = .; 
    *(.data_4) *(.data_2) *(.data_1) *(.data) *(.data.*) *(.gnu.linkonce.d.*) 
    __DATA_END = .; 
  } > ram AT > rom

  .bss (NOLOAD) : 
  {
    __BSS_START = .; 
    *(.bss_4) *(.bss_2) *(.bss_1) *(.bss) *(COMMON) *(.bss.*) *(.gnu.linkonce.b.*) 
    __BSS_END = .; 
  } > ram

/*
 You may change the sizes of the following sections to fit the actual
 size your program requires.
 The heap and stack are aligned to the bus width, as a speed optimization
 for accessing data located there.
*/
  .heap : 
  { 
    . = ALIGN(4); 
    __HEAP_START = .; 
    . += 0x2000; 
    __HEAP_MAX = .; 
  } > ram

  .stack : 
  { 
    . = ALIGN(4); 
    . += 0x6000; 
    __STACK_START = .; 
  } > ram

  .istack : 
  { 
    . = ALIGN(4); 
    . += 0x100; 
    __ISTACK_START = .; 
  } > ram
}

__DATA_IMAGE_START = LOADADDR(.data);
