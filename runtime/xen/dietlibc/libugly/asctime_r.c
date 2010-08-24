#include <time.h>

static const char days[] = "Sun Mon Tue Wed Thu Fri Sat ";
static const char months[] = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ";

static void num2str(char *c,int i) {
  c[0]=i/10+'0';
  c[1]=i%10+'0';
}

char *asctime_r(const struct tm *t, char *buf) {
  /* "Wed Jun 30 21:49:08 1993\n" */
  *(int*)buf=*(int*)(days+(t->tm_wday<<2));
  *(int*)(buf+4)=*(int*)(months+(t->tm_mon<<2));
  num2str(buf+8,t->tm_mday);
  if (buf[8]=='0') buf[8]=' ';
  buf[10]=' ';
  num2str(buf+11,t->tm_hour);
//  if (buf[11]=='0') buf[11]=' ';
  buf[13]=':';
  num2str(buf+14,t->tm_min);
  buf[16]=':';
  num2str(buf+17,t->tm_sec);
  buf[19]=' ';
  num2str(buf+20,(t->tm_year+1900)/100);
  num2str(buf+22,(t->tm_year+1900)%100);
  buf[24]='\n';
  return buf;
}
