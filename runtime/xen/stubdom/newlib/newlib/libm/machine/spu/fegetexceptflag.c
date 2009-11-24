#include "headers/fegetexceptflag.h"

void fegetexceptflag(fexcept_t *flagp, int excepts)
{
    _fegetexceptflag(flagp, excepts);
}
