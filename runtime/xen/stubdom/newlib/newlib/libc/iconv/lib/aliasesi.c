/*
 * Copyright (c) 2003-2004, Artem B. Bityuckiy
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#include <_ansi.h>
#include <reent.h>
#include <newlib.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include <sys/iconvnls.h>
#include "local.h"

/*
 * strnstr - locate a substring in a fixed-size string.
 *
 * PARAMETERS:
 *   _CONST char *haystack - the string in which to search.
 *   _CONST char *needle   - the string which to search.
 *   int length            - the maximum 'haystack' string length.
 *
 * DESCRIPTION:
 *   The  strstr() function finds the first occurrence of the substring 
 *   'needle' in the string 'haystack'. At most 'length' bytes are searched.
 *
 * RETURN:
 *   Returns a pointer to the beginning of substring, or NULL if substring
 *   was not found.
 */
static char *
_DEFUN(strnstr, (haystack, needle, length),
                _CONST char *haystack _AND
                _CONST char *needle   _AND
                int length)
{
  _CONST char *max = haystack + length;

  if (*haystack == '\0')
    return *needle == '\0' ? (char *)haystack : (char *)NULL;

  while (haystack < max)
    {
      int i = 0;
      while (1)
        {
          if (needle[i] == '\0')
            return (char *)haystack;
          if (needle[i] != haystack[i])
            break;
          i += 1;
        }
      haystack += 1;
    }
  return (char *)NULL;
}

/*
 * canonical_form - canonize 'str'.
 *
 * PARAMETERS:
 *   struct _reent *rptr - reent structure of current thread/process.
 *   _CONST char *str    - string to canonize. 
 *
 * DESCRIPTION:
 *   Converts all letters to small and substitute all '-' characters by '_'
 *   characters.
 *
 * RETURN:
 *   Returns canonical form of 'str' if success, NULL if failure.
 */
static _CONST char *
_DEFUN(canonical_form, (rptr, str), 
                       struct _reent *rptr _AND
                       _CONST char *str)
{
  char *p, *p1;

  if (str == NULL || (p = p1 = _strdup_r (rptr, str)) == NULL)
    return (_CONST char *)NULL;

  for (; *str; str++, p++)
    {
      if (*str == '-')
        *p = '_';
      else
        *p = tolower (*str);
    }

  return (_CONST char *)p1;
}

/*
 * find_alias - find encoding name name by it's alias. 
 *
 * PARAMETERS:
 *   struct _reent *rptr - reent structure of current thread/process.
 *   _CONST char *alias  - alias by which "official" name should be found.
 *   _CONST char *table  - aliases table.
 *   int len             - aliases table length.
 *
 * DESCRIPTION:
 *   'table' contains the list of encoding names and aliases. 
 *    Names go first, e.g.:
 *
 *   name1 alias11 alias12 alias1N
 *   name2 alias21 alias22 alias2N
 *   nameM aliasM1 aliasM2 aliasMN
 *
 *   If line begins with backspace it is considered as the continuation of
 *   previous line.
 *
 * RETURN:
 *   Returns pointer to name found if success. In case of error returns NULL
 *   and sets current thread's/process's errno.
 */
static char *
_DEFUN(find_alias, (rptr, alias, table, len),
                   struct _reent *rptr _AND
                   _CONST char *alias  _AND
                   _CONST char *table  _AND
                   int len)
{
  _CONST char *end;
  _CONST char *p;
  int l = strlen (alias);
  _CONST char *ptable = table;
  _CONST char *table_end = table + len;

  if (table == NULL || alias == NULL || *table == '\0' || *alias == '\0')
    return NULL;

search_again:
  if (len < l || (p = strnstr (ptable, alias, len)) == NULL)
    return NULL;
  
  /* Check that substring is segregated by '\n', '\t' or ' ' */
  if (!((p == table || isspace (*(p-1)) || *(p-1) == '\n')
     && (p+l == table_end || isspace (*(p+l)) || *(p+l) == '\n')))
    {
      ptable = p + l;
      len -= table - p;
      goto search_again;
    }

  while(--p > table && *p != '\n');

  if (*(++p) == '#')
    return NULL;

  for (end = p + 1; !isspace (*end) && *end != '\n' && *end != '\0'; end++);

  return _strndup_r (rptr, p, (size_t)(end - p));
}

/*
 * _iconv_resolve_encoding_name - resolves encoding's name by given alias. 
 *
 * PARAMETERS:
 *   struct _reent *rptr - reent structure of current thread/process.
 *   _CONST char *ca     - encoding alias to resolve.
 *
 * DESCRIPTION: 
 *   First, tries to find 'ca' among built-in aliases. If not found, tries to 
 *   find it external file.
 *
 * RETURN:
 *   Encoding name if found. In case of error returns NULL
 *   and sets current thread's/process's errno.
 */
char *
_DEFUN(_iconv_resolve_encoding_name, (rptr, cname, path), 
                                     struct _reent *rptr _AND
                                     _CONST char *ca)
{
  char *p = (char *)ca;

  /* Alias shouldn't contain white spaces, '\n' and '\r' symbols */ 
  while (*p)
    if (*p == ' ' || *p == '\r' || *p++ == '\n')
      return NULL;
    
  if ((ca = canonical_form (rptr, ca)) == NULL)
    return NULL;

  p = find_alias (rptr, ca, _iconv_aliases, strlen (_iconv_aliases));
  
  _free_r (rptr, (_VOID_PTR)ca);
  return p;
}

