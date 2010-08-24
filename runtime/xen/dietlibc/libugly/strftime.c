#include <sys/types.h>
#include <time.h>
#include "dietfeatures.h"

static const char   sweekdays [7] [4] = {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static const char   weekdays [7] [10] = {
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
};
static const char   smonths [12] [4] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};
static const char*  months [12] = {
    "January", "February", "March", "April", smonths[5-1], "June",
    "July", "August", "September", "October", "November", "December"
};
static const char   ampm [4] [3] = {
    "am", "pm",
    "AM", "PM"
};

static void i2a ( char* dest,unsigned long x )
{
    int  div = 10;
    *dest++ = x/div + '0';
    *dest++ = x%div + '0';
    *dest++ = '\0';
}

size_t  strftime ( char* dst, size_t max, const char* format, const struct tm* tm )
{
    char*         p = dst;
    const char*   src;
    unsigned long no;
    char          buf [5];

    if (!max) return 0;
    for ( ; *format != '\0'; format++ ) {
	if (*format == '%') {
	    if (*++format == '%') {
	        *p++ = '%';
	    }
	    else
again:
	    switch (*format) {
//          case '%': *p++ = '%';  				 break;			// reduce size of jump table
	    case 'n': *p++ = '\n'; 				 break;
	    case 't': *p++ = '\t'; 				 break;
	    case 'O': case 'E': ++format; goto again;
	    case 'c': src = "%b %a %d %k:%M:%S %Z %Y";        	 goto _strf;
	    case 'r': src = "%I:%M:%S %p";                    	 goto _strf;
	    case 'R': src = "%H:%M";      			 goto _strf;
	    case 'x': src = "%b %a %d";   			 goto _strf;
	    case 'X': src = "%k:%M:%S";   			 goto _strf;
	    case 'D': src = "%m/%d/%y";   			 goto _strf;
	    case 'T': src = "%H:%M:%S";
	       _strf: p  += strftime (p, (size_t)(dst+max-p), src, tm); 	 break;
	    case 'a': src = sweekdays [tm->tm_wday]; 		 goto _str;
	    case 'A': src = weekdays  [tm->tm_wday]; 		 goto _str;
	    case 'h':
	    case 'b': src = smonths   [tm->tm_mon];  		 goto _str;
	    case 'B': src = months    [tm->tm_mon];  		 goto _str;
	    case 'p': src = ampm [tm->tm_hour > 12 ? 3 : 2]; goto _str;
	    case 'P': src = ampm [tm->tm_hour > 12 ? 1 : 0]; goto _str;
	    case 'C': no  = tm->tm_year/100 + 19; 		 goto _no;
	    case 'd': no  = tm->tm_mday;          		 goto _no;
	    case 'e': no  = tm->tm_mday;          		 goto _nos;
	    case 'H': no  = tm->tm_hour;          		 goto _no;
	    case 'I': no  = tm->tm_hour % 12;     		 goto _no;
	    case 'j': no  = tm->tm_yday;          		 goto _no;
	    case 'k': no  = tm->tm_hour;          		 goto _nos;
	    case 'l': no  = tm->tm_hour % 12;     		 goto _nos;
	    case 'm': no  = tm->tm_mon + 1;         		 goto _no;
	    case 'M': no  = tm->tm_min;           		 goto _no;
	    case 'S': no  = tm->tm_sec;           		 goto _no;
	    case 'u': no  = tm->tm_wday ? tm->tm_wday : 7; 	 goto _no;
	    case 'w': no  = tm->tm_wday;              		 goto _no;
	    case 'U': no  = (tm->tm_yday - tm->tm_wday + 7) / 7; goto _no;
	    case 'W': no  = (tm->tm_yday - (tm->tm_wday - 1 + 7) % 7 + 7) / 7; goto _no;
	    case 's': {
			time_t t = mktime((struct tm*)tm);
			char buf[101];
			char* c;
			buf[100]=0;
			for (c=buf+99; c>buf; --c) {
			  *c=(t%10)+'0';
			  t/=10;
			  if (!t) break;
			}
			src=c;
			goto _str;
		      }
	    case 'Z':
#ifdef WANT_TZFILE_PARSER
		      tzset(); src = tzname[0];
#else
		      src = "[unknown timezone]";
#endif
		      goto _str;
	    case 'Y': i2a ( buf+0, (unsigned int)(tm->tm_year / 100 + 19) );
		      i2a ( buf+2, (unsigned int)(tm->tm_year % 100) );
		      src = buf;
		      goto _str;
	    case 'y': no  = tm->tm_year % 100; 			 goto _no;
		 _no: i2a ( buf, no );				 /* append number 'no' */
		      src = buf;
		      goto _str;
		_nos: i2a ( buf, no );				 /* the same, but '0'->' ' */
		      if (buf[0] == '0')
			  buf[0] = ' ';
		      src = buf;
		_str: while (*src  &&  p < dst+max)		 /* append string */
			  *p++ = *src++;
		      break;
	    };
	} else {
	    *p++ = *format;
	}

	if (p >= dst+max)
	    break;
    }

    *p = '\0';
    return p - dst;
}


