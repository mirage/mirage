#include "headers/feholdexcept.h"

int feholdexcept(fenv_t *envp)
{
    return _feholdexcept(envp);
}
