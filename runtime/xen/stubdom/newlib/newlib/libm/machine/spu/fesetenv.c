#include "headers/fesetenv.h"

void fesetenv(const fenv_t *envp)
{
    _fesetenv(envp);
}
