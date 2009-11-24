GROUP(-lc -lgcc -lmon960)

SECTIONS
{ 
    . = 0xa0008000;
    .text : 
    { 
	 CREATE_OBJECT_SYMBOLS
	*(.text) 
	 _etext = .;
	
	___CTOR_LIST__ = .;
	LONG((___CTOR_END__ - ___CTOR_LIST__) / 4 - 2)
	*(.ctors)
	LONG(0)
	___CTOR_END__ = .;
	___DTOR_LIST__ = .;
	LONG((___DTOR_END__ - ___DTOR_LIST__) / 4 - 2)
	*(.dtors)
	LONG(0)
	___DTOR_END__ = .;
    }  
    .data SIZEOF(.text) + ADDR(.text):
    { 
 	*(.data) 
	CONSTRUCTORS
	 _edata = .;
    }  
    .bss SIZEOF(.data) + ADDR(.data):
    { 
	 _bss_start = .;
	*(.bss)	 
	*(COMMON) 
	 _end = .;
    } 
} 
