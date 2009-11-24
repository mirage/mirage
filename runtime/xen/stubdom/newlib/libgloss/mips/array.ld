/*
 * memory map assumed by prom and standalone system
 *
 * physical     kseg1                   use
 *
 * 0x1fc20000   0xbfc20000
 * to                                   prom text and read-only data
 * 0x1fc00000   0xbfc00000              (in cpu board "prom space")
 *
 * (Top of RAM - 8K) downward           sash and standalone program stack
 *              |                       ( - 8K to preserve kernel message bufs)
 *              V                       (standalone programs grow their stack
 *                                       immediately below sash's stack)
 *
 *              ^
 *              |
 * 0x00100000   0xa0100000 upward       sash program text, data, and bss
 *
 *              ^
 *              |
 * 0x00020000   0xa0020000 upward       standalone program text, data, and bss
 *                                      (kernel is loaded here, also)
 *
 * 0x0001ffff   0xa001ffff downward     dbgmon stack
 *              |
 *              V
 *
 *              ^
 *              |
 * 0x00010000   0xa0010000 upward       dbgmon text, data, and bss
 *
 * 0x0000ffff   0xa000ffff downward     prom monitor stack
 *              |
 *              V
 *
 *              ^
 *              |
 * 0x00000500   0xa0000500 upward       prom monitor bss
 *
 * 0x000004ff   0xa00004ff
 * to                                   restart block
 * 0x00000400   0xa0000400
 *
 * 0x000003ff   0xa00003ff
 * to                                   general exception code
 * 0x00000080   0xa0000080              (note cpu addresses as 0x80000080!)
 *
 * 0x0000007f   0xa000007f
 * to                                   utlbmiss exception code
 * 0x00000000   0xa0000000              (note cpu addresses as 0x80000000!)
 */

/* Uncomment this if you want srecords. 
OUTPUT_FORMAT(srec)
 */
ENTRY(start)
STARTUP(crt0.o)
INPUT(array.o)
SEARCH_DIR(.)
__DYNAMIC  =  0;

/*
 * Allocate the stack to be at the top of memory, since the stack
 * grows down
 *
PROVIDE (__stack = 1M - 8);
 */

/*
 * Initalize some symbols to be zero so we can reference them in the
 * crt0 without core dumping. These functions are all optional, but
 * we do this so we can have our crt0 always use them if they exist. 
 * This is so BSPs work better when using the crt0 installed with gcc.
 * We have to initalize them twice, so we multiple object file
 * formats, as some prepend an underscore.
 */
PROVIDE (hardware_exit_hook = 0);
PROVIDE (hardware_hazard_hook = 0);
PROVIDE (hardware_init_hook = 0);
PROVIDE (software_init_hook = 0);

SECTIONS
{	
  . = 0x80020000;
  .text : {
     _ftext = . ;
    KEEP (*(.init))
     eprol  =  .;
    *(.text)
    *(.text.*)
    *(.gnu.linkonce.t.*)
    *(.mips16.fn.*)
    *(.mips16.call.*)
    PROVIDE (__runtime_reloc_start = .);
    *(.rel.sdata)
    PROVIDE (__runtime_reloc_stop = .);
    KEEP (*(.fini))
     etext  =  .;
     _etext  =  .;
  }
  
  .eh_frame_hdr : { *(.eh_frame_hdr) }
  .eh_frame : { KEEP (*(.eh_frame)) }
  .gcc_except_table : { *(.gcc_except_table) }
  .jcr : { KEEP (*(.jcr)) }
  .ctors    :
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

    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  }

  .dtors    :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  }

  . = .;
  .rdata : {
    *(.rdata)
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
  }
   _fdata = ALIGN(16);
  .data : {
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
  }
   _gp = ALIGN(16) + 0x8000;
  .lit8 : {
    *(.lit8)
  }
  .lit4 : {
    *(.lit4)
  }
  .sdata : {
    *(.sdata)
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
  }
   edata  =  .;
   _edata  =  .;
   _fbss = .;
  .sbss : {
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss : {
    _bss_start = . ;
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
  }
   end = .;
   _end = .;
}
