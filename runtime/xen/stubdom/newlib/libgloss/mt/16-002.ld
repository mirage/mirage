OUTPUT_FORMAT("elf32-mt", "elf32-mt", "elf32-mt")
OUTPUT_ARCH(mt)
ENTRY(__boot_start)

/* Do we need any of these for elf?
   __DYNAMIC = 0;    */
MEMORY
{
  ram (rwx) : ORIGIN = 0x0, LENGTH = 128K
  frame-buffer (w) : ORIGIN = 0xde0000, LENGTH = 40K
  ports (w) : ORIGIN = 0xfff000, LENGTH = 4K
  dma-ram (w) : ORIGIN = 0x1000000, LENGTH = 16M-4K
}
SECTIONS
{
  /* Read-only sections, merged into text segment: */
  . = 0x0;
  PROVIDE(__executable_start = 0x0);
  .interp         : { *(.interp) }
  .hash           : { *(.hash) }
  .dynsym         : { *(.dynsym) }
  .dynstr         : { *(.dynstr) }
  .gnu.version    : { *(.gnu.version) }
  .gnu.version_d  : { *(.gnu.version_d) }
  .gnu.version_r  : { *(.gnu.version_r) }
  .rel.init       : { *(.rel.init) }
  .rela.init      : { *(.rela.init) }
  .rel.text       : { *(.rel.text .rel.text.* .rel.gnu.linkonce.t.*) }
  .rela.text      : { *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*) }
  .rel.fini       : { *(.rel.fini) }
  .rela.fini      : { *(.rela.fini) }
  .rel.rodata     : { *(.rel.rodata .rel.rodata.* .rel.gnu.linkonce.r.*) }
  .rela.rodata    : { *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*) }
  .rel.data.rel.ro  : { *(.rel.data.rel.ro*) }
  .rela.data.rel.ro : { *(.rela.data.rel.ro*) }
  .rel.data       : { *(.rel.data .rel.data.* .rel.gnu.linkonce.d.*) }
  .rela.data      : { *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*) }
  .rel.tdata      : { *(.rel.tdata .rel.tdata.* .rel.gnu.linkonce.td.*) }
  .rela.tdata     : { *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*) }
  .rel.tbss       : { *(.rel.tbss .rel.tbss.* .rel.gnu.linkonce.tb.*) }
  .rela.tbss      : { *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*) }
  .rel.ctors      : { *(.rel.ctors) }
  .rela.ctors     : { *(.rela.ctors) }
  .rel.dtors      : { *(.rel.dtors) }
  .rela.dtors     : { *(.rela.dtors) }
  .rel.got        : { *(.rel.got) }
  .rela.got       : { *(.rela.got) }
  .rel.sdata      : { *(.rel.sdata .rel.sdata.* .rel.gnu.linkonce.s.*) }
  .rela.sdata     : { *(.rela.sdata .rela.sdata.* .rela.gnu.linkonce.s.*) }
  .rel.sbss       : { *(.rel.sbss .rel.sbss.* .rel.gnu.linkonce.sb.*) }
  .rela.sbss      : { *(.rela.sbss .rela.sbss.* .rel.gnu.linkonce.sb.*) }
  .rel.sdata2     : { *(.rel.sdata2 .rel.sdata2.* .rel.gnu.linkonce.s2.*) }
  .rela.sdata2    : { *(.rela.sdata2 .rela.sdata2.* .rela.gnu.linkonce.s2.*) }
  .rel.sbss2      : { *(.rel.sbss2 .rel.sbss2.* .rel.gnu.linkonce.sb2.*) }
  .rela.sbss2     : { *(.rela.sbss2 .rela.sbss2.* .rela.gnu.linkonce.sb2.*) }
  .rel.bss        : { *(.rel.bss .rel.bss.* .rel.gnu.linkonce.b.*) }
  .rela.bss       : { *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*) }
  .rel.plt        : { *(.rel.plt) }
  .rela.plt       : { *(.rela.plt) }

  .startup        : { *startup-16-002.o(.startup) } >ram =0 
  . = 0x40 ;

  .init           : { KEEP (*(.init)) } >ram =0 
  .plt            : { *(.plt) } >ram
  .text           :
  {
    *startup-16-002.o(.text)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    KEEP (*(.text.*personality*))
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
  } >ram =0
  .fini           : { KEEP (*(.fini)) } >ram =0
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  .rodata         : { *(.rodata .rodata.* .gnu.linkonce.r.*) } >ram
  .rodata1        : { *(.rodata1) } >ram
  .sdata2         : { *(.sdata2 .sdata2.* .gnu.linkonce.s2.*) } >ram
  .sbss2          : { *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*) } >ram
  .eh_frame_hdr   : { *(.eh_frame_hdr) } >ram
  .eh_frame       : ONLY_IF_RO { KEEP (*(.eh_frame)) } >ram
  .gcc_except_table : ONLY_IF_RO { KEEP (*(.gcc_except_table)) *(.gcc_except_table.*) } >ram
  /* Adjust the address for the data segment.  We want to adjust up to
     the same address within the page on the next page up.  */
  . = ALIGN(256) + (. & (256 - 1));
  /* Exception handling  */
  .eh_frame       : ONLY_IF_RW { KEEP (*(.eh_frame)) } >ram
  .gcc_except_table   : ONLY_IF_RW { KEEP (*(.gcc_except_table)) *(.gcc_except_table.*) } >ram
  /* Thread Local Storage sections  */
  .tdata          : { *(.tdata .tdata.* .gnu.linkonce.td.*) } >ram
  .tbss           : { *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon) } >ram
  /* Ensure the __preinit_array_start label is properly aligned.  We
     could instead move the label definition inside the section, but
     the linker would then create the section even if it turns out to
     be empty, which isn't pretty.  */
  . = ALIGN(32 / 8);
  PROVIDE (__preinit_array_start = .);
  .preinit_array  : { *(.preinit_array) } >ram
  PROVIDE (__preinit_array_end = .);
  PROVIDE (__init_array_start = .);
  .init_array     : { *(.init_array) } >ram
  PROVIDE (__init_array_end = .);
  PROVIDE (__fini_array_start = .);
  .fini_array     : { *(.fini_array) } >ram
  PROVIDE (__fini_array_end = .);
  .ctors :
  {
    /* gcc uses crtbegin.o to find the start of
       the constructors, so we make sure it is
       first.  Because this is a wildcard, it
       doesn't matter if the user does not
       actually link against crtbegin.o; the
       linker won't look for a file to match a
       wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o
       is in.  */
    KEEP (*crtbegin.o(.ctors))
    /* We don't want to include the .ctor section from
       from the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  } >ram
  .dtors :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } >ram
  .jcr            : { KEEP (*(.jcr)) } >ram
  .data.rel.ro    : { *(.data.rel.ro.local) *(.data.rel.ro*) } >ram
  .dynamic        : { *(.dynamic) } >ram

  /* DJK - Re-align the data section from the read-only section. */
  . = ALIGN(16) + (. & (16 - 1));
  PROVIDE (_data = .);
  .data           :
  {
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  } >ram
  .data1          : { *(.data1) } >ram
  .got            : { *(.got.plt) *(.got) } >ram

  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
  .sdata          : { *(.sdata .sdata.* .gnu.linkonce.s.*) } >ram
  _edata = .;
  PROVIDE ( edata = . ) ;
  .sbss           :
  {
    PROVIDE (__sbss_start = .);
    PROVIDE (___sbss_start = .);
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    PROVIDE (__sbss_end = .);
    PROVIDE (___sbss_end = .);
  } >ram
  .bss            :
  {
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    /* Align here to ensure that the .bss section occupies space up to
       _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.  */
    . = ALIGN(32 / 8);
  } >ram
  . = ALIGN(32 / 8);
  __bss_start = ADDR ( .sbss ) ;
  __bss_end = __bss_start + SIZEOF ( .sbss ) + SIZEOF ( .bss ) - 4 ;
  _end = .;
  PROVIDE (end = .);

  /* DJK - Initialized frame buffer data is copied from RAM to FB. */
  .auxbss         : AT (ADDR(.bss) + SIZEOF(.bss)) { *(.auxbss) } >frame-buffer
  .auxdata        : AT (LOADADDR(.auxbss) + SIZEOF(.auxbss))
  {
    *(.auxdata)
  } >frame-buffer

  _fbbss_start = ADDR ( .auxbss );
  _fbbss_end = _fbbss_start + SIZEOF ( .auxbss ) - 4;
  _fbdata_start = LOADADDR ( .auxdata );
  _fbdata_end = _fbdata_start + SIZEOF ( .auxdata ) ;
  _fbdata_vma = ADDR ( .auxdata );

  PROVIDE (__FRAME_BUFFER_START = ADDR(.auxbss) );
  PROVIDE (__FRAME_BUFFER_SIZE = 0xa000);
  PROVIDE (__FRAME_BUFFER_END = __FRAME_BUFFER_START + __FRAME_BUFFER_SIZE);

  .dma            : { _dma_start = .; *(.dma) _dma_end = .; } >dma-ram
  .internal_io (NOLOAD) : { *(.internal_io) } >ports 

  /* Stabs debugging sections.  */
  .stab            0 : { *(.stab) }
  .stabstr         0 : { *(.stabstr) }
  .stab.excl       0 : { *(.stab.excl) }
  .stab.exclstr    0 : { *(.stab.exclstr) }
  .stab.index      0 : { *(.stab.index) }
  .stab.indexstr   0 : { *(.stab.indexstr) }
  .comment         0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug           0 : { *(.debug) }
  .line            0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo   0 : { *(.debug_srcinfo) }
  .debug_sfnames   0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges   0 : { *(.debug_aranges) }
  .debug_pubnames  0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info      0 : { *(.debug_info) *(.gnu.linkonce.wi.*) }
  .debug_abbrev    0 : { *(.debug_abbrev) }
  .debug_line      0 : { *(.debug_line) }
  .debug_frame     0 : { *(.debug_frame) }
  .debug_str       0 : { *(.debug_str) }
  .debug_loc       0 : { *(.debug_loc) }
  .debug_macinfo   0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }

  /* In a multi-core environment, each core is given its own stack space
     equal to __stack_size. */
  PROVIDE (__stack = 0x1fff0);
  PROVIDE (__stack_size = 0x800);

  .stack (DEFINED(__stack) ? __stack : 0x007ffff0) :
  {
     __stack = .;
    *(.stack)
    LONG(0xdeaddead)
  }
  /DISCARD/ : { *(.note.GNU-stack) }
}
