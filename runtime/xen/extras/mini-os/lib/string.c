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

#if !defined HAVE_LIBC

#include <mini-os/os.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>

int memcmp(const void * cs,const void * ct,size_t count)
{
	const unsigned char *su1, *su2;
	signed char res = 0;

	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
		if ((res = *su1 - *su2) != 0)
			break;
	return res;
}

void * memcpy(void * dest,const void *src,size_t count)
{
	char *tmp = (char *) dest;
    const char *s = src;

	while (count--)
		*tmp++ = *s++;

	return dest;
}

int strncmp(const char * cs,const char * ct,size_t count)
{
	register signed char __res = 0;

	while (count) {
		if ((__res = *cs - *ct++) != 0 || !*cs++)
			break;
		count--;
	}

	return __res;
}

int strcmp(const char * cs,const char * ct)
{
        register signed char __res;

        while (1) {
                if ((__res = *cs - *ct++) != 0 || !*cs++)
                        break;
        }

        return __res;
}

char * strcpy(char * dest,const char *src)
{
        char *tmp = dest;

        while ((*dest++ = *src++) != '\0')
                /* nothing */;
        return tmp;
}

char * strncpy(char * dest,const char *src,size_t count)
{
        char *tmp = dest;

        while (count-- && (*dest++ = *src++) != '\0')
                /* nothing */;

        return tmp;
}

void * memset(void * s,int c,size_t count)
{
        char *xs = (char *) s;

        while (count--)
                *xs++ = c;

        return s;
}

size_t strnlen(const char * s, size_t count)
{
        const char *sc;

        for (sc = s; count-- && *sc != '\0'; ++sc)
                /* nothing */;
        return sc - s;
}


char * strcat(char * dest, const char * src)
{
    char *tmp = dest;
    
    while (*dest)
        dest++;
    
    while ((*dest++ = *src++) != '\0');
    
    return tmp;
}

size_t strlen(const char * s)
{
	const char *sc;

	for (sc = s; *sc != '\0'; ++sc)
		/* nothing */;
	return sc - s;
}

char * strchr(const char * s, int c)
{
        for(; *s != (char) c; ++s)
                if (*s == '\0')
                        return NULL;
        return (char *)s;
}

char * strrchr(const char * s, int c)
{
        const char *res = NULL;
        for(; *s != '\0'; ++s)
                if (*s == (char) c)
                        res = s;
        return (char *)res;
}

char * strstr(const char * s1,const char * s2)
{
        int l1, l2;

        l2 = strlen(s2);
        if (!l2)
                return (char *) s1;
        l1 = strlen(s1);
        while (l1 >= l2) {
                l1--;
                if (!memcmp(s1,s2,l2))
                        return (char *) s1;
                s1++;
        }
        return NULL;
}

char *strdup(const char *x)
{
    int l = strlen(x);
    char *res = malloc(l + 1);
	if (!res) return NULL;
    memcpy(res, x, l + 1);
    return res;
}

int ffs(int i)
{
   int c = 1;

   do {
      if (i & 1)
         return (c);
      i = i >> 1;
      c++;
   } while (i);
   return 0;
}

#endif
