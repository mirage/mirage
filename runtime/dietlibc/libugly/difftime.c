#include <time.h>
#include "../dietwarning.h"

double difftime(time_t time1, time_t time2) {
    return (double)time1 - (double)time2;
}

link_warning("difftime","warning: difftime introduces an unnecessary floating point dependency. Don't use it!")
