#include "dietfeatures.h"
#include <string.h>
#include <utmp.h>
#include "dietwarning.h"

#define _GNU_SOURCE
#include <utmpx.h>

void
getutmp (const struct utmpx *utmpx, struct utmp *utmp)
{
    memcpy (utmp, utmpx, sizeof(struct utmp));
    return;
}

void
getutmpx (const struct utmp *utmp, struct utmpx *utmpx)
{
    memcpy (utmpx, utmp, sizeof(struct utmpx));
    return;
}

link_warning("getutmp","getutmp(): dietlibc utmp and utmpx structures are identical.  If you actually require conversion, this it NOT the place to find it!");

link_warning("getutmpx","getutmpx(): dietlibc utmp and utmpx structures are identical.  If you actually require conversion, this it NOT the place to find it!");
