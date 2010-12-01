int __isxdigit_ascii ( int ch );
int __isxdigit_ascii ( int ch )
{
    return (unsigned int)( ch         - '0') < 10u  || 
           (unsigned int)((ch | 0x20) - 'a') <  6u;
}

int isxdigit ( int ch ) __attribute__((weak,alias("__isxdigit_ascii")));
