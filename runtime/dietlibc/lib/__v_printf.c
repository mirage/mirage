#include "dietfeatures.h"
#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "dietstdio.h"
#include "dietwarning.h"

#define MAX_WIDTH 10*1024

static inline unsigned long skip_to(const char *format) {
  unsigned long nr;
  for (nr=0; format[nr] && (format[nr]!='%'); ++nr);
  return nr;
}

#define A_WRITE(fn,buf,sz)	((fn)->put((void*)(buf),(sz),(fn)->data))
#define B_WRITE(fn,buf,sz)	{ if ((unsigned long)(sz) > (((unsigned long)(int)(-1))>>1) || len+(int)(sz)<len) return -1; A_WRITE(fn,buf,sz); } while (0)

static const char pad_line[2][16]= { "                ", "0000000000000000", };
static int write_pad(unsigned int* dlen,struct arg_printf* fn, unsigned int len, int padwith) {
  int nr=0;
  if ((int)len<=0) return 0;
  if(*dlen+len<len) return -1;
  for (;len>15;len-=16,nr+=16) {
    A_WRITE(fn,pad_line[(padwith=='0')?1:0],16);
  }
  if (len>0) {
    A_WRITE(fn,pad_line[(padwith=='0')?1:0],(unsigned int)len); nr+=len;
  }
  *dlen += nr;
  return 0;
}

int __v_printf(struct arg_printf* fn, const char *format, va_list arg_ptr)
{
  unsigned int len=0;
#ifdef WANT_ERROR_PRINTF
  int _errno = errno;
#endif

  while (*format) {
    unsigned long sz = skip_to(format);
    if (sz) {
      B_WRITE(fn,format,sz); len+=sz;
      format+=sz;
    }
    if (*format=='%') {
      char buf[128];
      union { char*s; } u_str;
#define s u_str.s

      int retval;
      unsigned char ch, padwith=' ', precpadwith=' ';

      char flag_in_sign=0;
      char flag_upcase=0;
      char flag_hash=0;
      char flag_left=0;
      char flag_space=0;
      char flag_sign=0;
      char flag_dot=0;
      signed char flag_long=0;

      unsigned int base;
      unsigned int width=0, preci=0;

      long number=0;
#ifdef WANT_LONGLONG_PRINTF
      long long llnumber=0;
#endif

      ++format;
inn_printf:
      switch(ch=*format++) {
      case 0:
	return -1;
	break;

      /* FLAGS */
      case '#':
	flag_hash=-1;

      case 'h':
	--flag_long;
	goto inn_printf;
#if __WORDSIZE != 64
      case 'j':
#endif
      case 'q':		/* BSD ... */
      case 'L':
	++flag_long; /* fall through */
#if __WORDSIZE == 64
      case 'j':
#endif
      case 'z':
      case 'l':
	++flag_long;
	goto inn_printf;

      case '-':
	flag_left=1;
	goto inn_printf;

      case ' ':
	flag_space=1;
	goto inn_printf;

      case '+':
	flag_sign=1;
	goto inn_printf;

      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
	if(flag_dot) return -1;
	width=strtoul(format-1,(char**)&s,10);
	if (width>MAX_WIDTH) return -1;
	if (ch=='0' && !flag_left) padwith='0';
	format=s;
	goto inn_printf;

      case '*':
	{
	  /* A negative field width is taken as a '-' flag followed by
	   * a positive field width
	   **/
	  int tmp;
	  if ((tmp=va_arg(arg_ptr,int))<0) {
	    flag_left=1;
	    tmp=-tmp;
	  }
	  if ((width=(unsigned long)tmp)>MAX_WIDTH) return -1;
	  goto inn_printf;
	}
      case '.':
	flag_dot=1;
	if (*format=='*') {
	  int tmp=va_arg(arg_ptr,int);
	  preci=tmp<0?0:tmp;
	  ++format;
	} else {
	  long int tmp=strtol(format,(char**)&s,10);
	  preci=tmp<0?0:tmp;
	  format=s;
	}
	if (preci>MAX_WIDTH) return -1;
	goto inn_printf;

      /* print a char or % */
      case 'c':
	ch=(char)va_arg(arg_ptr,int);
      case '%':
	B_WRITE(fn,&ch,1); ++len;
	break;

#ifdef WANT_ERROR_PRINTF
      /* print an error message */
      case 'm':
	s=strerror(_errno);
	sz=strlen(s);
	B_WRITE(fn,s,sz); len+=sz;
	break;
#endif
      /* print a string */
      case 's':
	s=va_arg(arg_ptr,char *);
#ifdef WANT_NULL_PRINTF
	if (!s) s="(null)";
#endif
	sz = strlen(s);
	if (flag_dot && sz>preci) sz=preci;
	preci=0;
	flag_dot^=flag_dot;
	padwith=precpadwith=' ';

print_out:
      {
	char *sign=s;
	int todo=0;
	int vs;
	
	if (! (width||preci) ) {
	  B_WRITE(fn,s,sz); len+=sz;
	  break;
	}
	
	if (flag_in_sign) todo=1;
	if (flag_hash>0)  todo=flag_hash;
	if (todo) {
	  s+=todo;
	  sz-=todo;
	  width-=todo;
	}

	/* These are the cases for 1234 or "1234" respectively:
	      %.6u -> "001234"
	      %6u  -> "  1234"
	      %06u -> "001234"
	      %-6u -> "1234  "
	      %.6s -> "1234"
	      %6s  -> "  1234"
	      %06s -> "  1234"
	      %-6s -> "1234  "
	      %6.5u -> " 01234"
	      %6.5s -> "  1234"
           In this code, for %6.5s, 6 is width, 5 is preci.
	   flag_dot means there was a '.' and preci is set.
	   flag_left means there was a '-'.
	   sz is 4 (strlen("1234")).
	   padwith will be '0' for %06u, ' ' otherwise.
	   precpadwith is '0' for %u, ' ' for %s.
	 */

	if (flag_dot && width==0) width=preci;
	if (!flag_dot) preci=sz;
	if (!flag_left && padwith==' ') { /* do left-side padding with spaces */
	  if (write_pad(&len,fn,width-preci,padwith))
	    return -1;
	}
	if (todo) {
	  B_WRITE(fn,sign,todo);
	  len+=todo;
	}
	if (!flag_left && padwith!=' ') { /* do left-side padding with '0' */
	  if (write_pad(&len,fn,width-preci,padwith))
	    return -1;
	}
	/* do preci padding */
	if (write_pad(&len,fn,preci-sz,precpadwith))
	  return -1;
	/* write actual string */
	B_WRITE(fn,s,sz); len+=sz;
	if (flag_left) {
	  if (write_pad(&len,fn,width-preci,padwith))
	    return -1;
	}
	
	break;
      }

      /* print an integer value */
      case 'b':
	base=2;
	sz=0;
	goto num_printf;
      case 'p':
	flag_hash=2;
	flag_long=1;
	ch='x';
      case 'X':
	flag_upcase=(ch=='X');
      case 'x':
	base=16;
	sz=0;
	if (flag_hash) {
	  buf[1]='0';
	  buf[2]=ch;
	  flag_hash=2;
	  sz=2;
	}
	if (preci>width) width=preci;
	goto num_printf;
      case 'd':
      case 'i':
	flag_in_sign=1;
      case 'u':
	base=10;
	sz=0;
	goto num_printf;
      case 'o':
	base=8;
	sz=0;
	if (flag_hash) {
	  buf[1]='0';
	  flag_hash=1;
	  ++sz;
	}

num_printf:
	s=buf+1;

	if (flag_long>0) {
#ifdef WANT_LONGLONG_PRINTF
	  if (flag_long>1)
	    llnumber=va_arg(arg_ptr,long long);
	  else
#endif
	    number=va_arg(arg_ptr,long);
	}
	else {
	  number=va_arg(arg_ptr,int);
	  if (sizeof(int) != sizeof(long) && !flag_in_sign)
	    number&=((unsigned int)-1);
	}

	if (flag_in_sign) {
#ifdef WANT_LONGLONG_PRINTF
	  if ((flag_long>1)&&(llnumber<0)) {
	    llnumber=-llnumber;
	    flag_in_sign=2;
	  } else
#endif
	    if (number<0) {
	      number=-number;
	      flag_in_sign=2;
	    }
	}
	if (flag_long<0) number&=0xffff;
	if (flag_long<-1) number&=0xff;
#ifdef WANT_LONGLONG_PRINTF
	if (flag_long>1)
	  retval = __lltostr(s+sz,sizeof(buf)-5,(unsigned long long) llnumber,base,flag_upcase);
	else
#endif
	  retval = __ltostr(s+sz,sizeof(buf)-5,(unsigned long) number,base,flag_upcase);

	/* When 0 is printed with an explicit precision 0, the output is empty. */
	if (flag_dot && retval == 1 && s[sz] == '0') {
	  if (preci == 0||flag_hash > 0) {
	    sz = 0;
	  }
	  flag_hash = 0;
	} else sz += retval;

	if (flag_in_sign==2) {
	  *(--s)='-';
	  ++sz;
	} else if ((flag_in_sign)&&(flag_sign || flag_space)) {
	  *(--s)=(flag_sign)?'+':' ';
	  ++sz;
	} else flag_in_sign=0;

	precpadwith='0';

	goto print_out;

#ifdef WANT_FLOATING_POINT_IN_PRINTF
      /* print a floating point value */
      case 'f':
      case 'g':
	{
	  int g=(ch=='g');
	  double d=va_arg(arg_ptr,double);
	  s=buf+1;
	  if (width==0) width=1;
	  if (!flag_dot) preci=6;
	  if (flag_sign || d < +0.0) flag_in_sign=1;

	  sz=__dtostr(d,s,sizeof(buf)-1,width,preci,g);

	  if (flag_dot) {
	    char *tmp;
	    if ((tmp=strchr(s,'.'))) {
	      if (preci || flag_hash) ++tmp;
	      while (preci>0 && *++tmp) --preci;
	      *tmp=0;
	    } else if (flag_hash) {
	      s[sz]='.';
	      s[++sz]='\0';
	    }
	  }

	  if (g) {
	    char *tmp,*tmp1;	/* boy, is _this_ ugly! */
	    if ((tmp=strchr(s,'.'))) {
	      tmp1=strchr(tmp,'e');
	      while (*tmp) ++tmp;
	      if (tmp1) tmp=tmp1;
	      while (*--tmp=='0') ;
	      if (*tmp!='.') ++tmp;
	      *tmp=0;
	      if (tmp1) strcpy(tmp,tmp1);
	    }
	  }
	  
	  if ((flag_sign || flag_space) && d>=0) {
	    *(--s)=(flag_sign)?'+':' ';
	    ++sz;
	  }
	  
	  sz=strlen(s);
	  if (width<sz) width=sz;
	  precpadwith='0';
	  flag_dot=0;
	  flag_hash=0;
	  goto print_out;
	}
#endif

      default:
	break;
      }
    }
  }
  return len;
}

link_warning("__v_printf","warning: the printf functions add several kilobytes of bloat.")
