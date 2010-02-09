#include <string.h>
#include <strings.h>
#include "dietfeatures.h"
#include <errno.h>
#include <stdlib.h>
#include "dieticonv.h"

static enum charset parsecharset(const char* s) {
  if (!strcasecmp(s,"UTF-8")) return UTF_8; else
  if (!strcasecmp(s,"UCS-2") || !strcasecmp(s,"UCS2")) return UCS_2; else
  if (!strcasecmp(s,"UCS-4") || !strcasecmp(s,"UCS4")) return UCS_4; else
  if (!strcasecmp(s,"ISO-8859-1") || !strcasecmp(s,"LATIN1")) return ISO_8859_1; else
  if (!strcasecmp(s,"US-ASCII")) return ISO_8859_1; else
  if (!strcasecmp(s,"UTF-16")) return UTF_16; else
  if (!strcasecmp(s,"UTF-16BE")) return UTF_16_BE; else
  if (!strcasecmp(s,"UTF-16LE")) return UTF_16_LE; else
  return INVALID;
}

iconv_t iconv_open(const char* tocode, const char* fromcode) {
  int f,t;

  f=parsecharset(fromcode);
  t=parsecharset(tocode);

  if (f==INVALID || t==INVALID) {
    errno=EINVAL;
    return (iconv_t)(-1);
  }
  return (f|t<<16);
}
