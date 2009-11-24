OUTPUT_FORMAT("elf64-ia64-little")
OUTPUT_ARCH(ia64)

ENTRY(phys_start)

PHDRS
{
  code PT_LOAD;
  data PT_LOAD;
}

SECTIONS
{

  phys_start = _start - (((5<<(61))+0x100000000) - (1 << 20));

  code : { } :code
  . = ((5<<(61))+0x100000000);

  _text = .;

  .text : AT(ADDR(.text) - (((5<<(61))+0x100000000) - (1 << 20)))
  {
    *(.text)
  }

  _etext = .;

  data : { } :data
  .data : AT(ADDR(.data) - (((5<<(61))+0x100000000) - (1 << 20)))
  { *(.data) 
  }

  .sdata : AT(ADDR(.sdata) - (((5<<(61))+0x100000000) - (1 << 20)))
        { *(.sdata) *(.sdata1) *(.srdata) }

  .rodata : AT(ADDR(.rodata) - (((5<<(61))+0x100000000) - (1 << 20)))
  { *(.rodata) }

  .rodata.str1.8 : AT(ADDR(.rodata.str1.8) - (((5<<(61))+0x100000000) - (1 << 20)))
  { *(.rodata.str1.8) }

  /* newlib initialization functions */
  . = ALIGN(64 / 8);
  PROVIDE (__preinit_array_start = .);
  .preinit_array     : { *(.preinit_array) }
  PROVIDE (__preinit_array_end = .);
  PROVIDE (__init_array_start = .);
  .init_array     : { *(.init_array) }
  PROVIDE (__init_array_end = .);
  PROVIDE (__fini_array_start = .);
  .fini_array     : { *(.fini_array) }
  PROVIDE (__fini_array_end = .);

  .ctors : AT(ADDR(.ctors) - (((5<<(61))+0x100000000) - (1 << 20)))
	{
        __CTOR_LIST__ = .;
        QUAD((__CTOR_END__ - __CTOR_LIST__) / 8 - 2)
        *(.ctors)
	CONSTRUCTORS
        QUAD(0)
        __CTOR_END__ = .;
        }

  .dtors : AT(ADDR(.dtors) - (((5<<(61))+0x100000000) - (1 << 20)))
        {
        __DTOR_LIST__ = .;
        QUAD((__DTOR_END__ - __DTOR_LIST__) / 8 - 2)
        *(.dtors)
        QUAD(0)
        __DTOR_END__ = .;
        }

  .IA_64.unwind_info : AT(ADDR(.IA_64.unwind_info) - (((5<<(61))+0x100000000) - (1 << 20)))
  { *(.IA_64.unwind_info) }

  .IA_64.unwind : AT(ADDR(.IA_64.unwind) - (((5<<(61))+0x100000000) - (1 << 20)))
  { *(.IA_64.unwind) }

  .bss : AT(ADDR(.bss) - (((5<<(61))+0x100000000) - (1 << 20)))
  {
    *(.bss)
    *(.app.bss)
  }

  _end = .;

}
