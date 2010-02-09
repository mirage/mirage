
#include "_dl_int.h"

#ifdef __DIET_LD_SO__
static unsigned int _dl_error;
static const char*_dl_error_location;
static const char*_dl_error_data;
#else
#include <string.h>
unsigned int _dl_error;
const char*_dl_error_location;
const char*_dl_error_data;
#endif

static struct _dl_err_msg {
  char*msg;
  int len;
} _dl_error_msg[]={
#define MSG(n) { (n), sizeof((n))-1 }
  MSG("can't open: "),					/* 1 */
  MSG("can't stat: "),					/* 2 */
  MSG("shared object is not position independent: "),	/* 3 */
  MSG("can't resolve all symbols in: "),		/* 4 */
  MSG("can't find symbol: "),				/* 5 */
  MSG("invalid relocation type in: "),			/* 6 */
  MSG("internal error: layout not yet supported: "),	/* 7 */
};

const char *dlerror(void) {
  static char buf[1024],*p=buf;
  register int l,len=sizeof(buf)-1;
  if (_dl_error==0) return 0;

  buf[0]=0;
  buf[len]=0;
  --_dl_error;

  if (_dl_error>=DIV(sizeof(_dl_error_msg),sizeof(struct _dl_err_msg)))
    return "HAE ?!?";

  if (_dl_error_location) {
    l=_dl_lib_strlen(_dl_error_location);
    _dl_lib_strncpy(p,_dl_error_location,len); len-=l; p+=l;
    _dl_lib_strncpy(p,": ",len); len-=2; p+=2;
  }
  l=_dl_error_msg[_dl_error].len;
  _dl_lib_strncpy(p,_dl_error_msg[_dl_error].msg,len); len-=l; p+=l;
  _dl_lib_strncpy(p,_dl_error_data,len);

  _dl_error_location=0;
  _dl_error_data="";
  _dl_error=0;

  return buf;
}
