SECTIONS
{
        .app.bss : {
                __app_bss_start = . ;
                *(.bss .bss.*)
                *(COMMON)
                *(.lbss .lbss.*)
                *(LARGE_COMMON)
                __app_bss_end = . ;
        }
}
