/* -*-  Mode:C; c-basic-offset:4; tab-width:4 -*-
 ****************************************************************************
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: string.c
 *      Author: Rolf Neugebauer (neugebar@dcs.gla.ac.uk)
 *     Changes: 
 *              
 *        Date: Aug 2003
 * 
 * Environment: Xen Minimal OS
 * Description: Library function for string and memory manipulation
 *              Origin unknown
 *
 ****************************************************************************
 * $Id: c-insert.c,v 1.7 2002/11/08 16:04:34 rn Exp $
 ****************************************************************************
 */

#include <strings.h>

/* newlib defines ffs but not ffsll or ffsl */
int __ffsti2 (long long int lli)
{
    int i, num, t, tmpint, len;

    num = sizeof(long long int) / sizeof(int);
    if (num == 1) return (ffs((int) lli));
    len = sizeof(int) * 8;

    for (i = 0; i < num; i++) {
        tmpint = (int) (((lli >> len) << len) ^ lli);

        t = ffs(tmpint);
        if (t)
            return (t + i * len);
        lli = lli >> len;
    }
    return 0;
}

int __ffsdi2 (long int li)
{
    return __ffsti2 ((long long int) li);
}

int ffsl (long int li)
{
    return __ffsti2 ((long long int) li);
}

int ffsll (long long int lli)
{
    return __ffsti2 (lli);
}
