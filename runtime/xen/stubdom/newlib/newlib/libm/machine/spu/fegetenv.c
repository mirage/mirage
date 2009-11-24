#include "headers/fegetenv.h"

void fegetenv(fenv_t *envp)
{
    _fegetenv(envp);
}
