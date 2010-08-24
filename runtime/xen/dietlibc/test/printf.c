#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/param.h>
#include <locale.h>

#define ALGN		5

// https://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=112986
#if 0
#undef  assert
#define assert(X)	if (!(X)) { write(2, #X "\n", sizeof(#X));  *(char *)0 = 0; }
#endif

#define TEST_INIT(EXP)					\
  char		buf[sizeof(EXP)+ALGN*3+16];		\
  int		rc;					\
  memset(buf, cmp[0], sizeof buf)

#define TEST_CHECK(EXP,SZ)				\
  assert(rc==sizeof(EXP)-1);				\
  assert(memcmp(buf,cmp,ALGN)==0);			\
  if ((SZ)>=0) {					\
    assert(memcmp(buf+ALGN,(EXP),(SZ))==0);		\
    assert(buf[ALGN+(SZ)]=='\0');			\
  }							\
  assert(memcmp(buf+ALGN+(SZ)+1,cmp,ALGN)==0)


#define TEST_SPRINTF(EXP,...)				\
  {							\
    TEST_INIT(EXP);					\
    rc=sprintf(buf+ALGN,__VA_ARGS__);			\
    TEST_CHECK(EXP,rc);					\
  }

#define TEST_SNPRINTF(EXP,SZ, ...)			\
  {							\
    volatile char * args[] = { EXP, #SZ };		\
    ssize_t	test_sz=MIN((SZ),sizeof(EXP))-1;	\
    (void)args;						\
    TEST_INIT(EXP);					\
    rc=snprintf(buf+ALGN,(SZ),__VA_ARGS__);		\
    TEST_CHECK(EXP, test_sz);				\
  }

#define TEST_SNPRINTF_NULL(EXP, ...)			\
  {							\
    int rc=snprintf(0,0, __VA_ARGS__);			\
    assert(rc==sizeof(EXP)-1);				\
  }

#define TEST(EXP, ...)						\
  TEST_SPRINTF (EXP, __VA_ARGS__);				\
  TEST_SNPRINTF(EXP,  sizeof(EXP)+1,    __VA_ARGS__);		\
  TEST_SNPRINTF(EXP,  sizeof(EXP),      __VA_ARGS__);		\
  TEST_SNPRINTF(EXP,  sizeof(EXP)-1,    __VA_ARGS__);		\
  TEST_SNPRINTF(EXP,  1,                __VA_ARGS__);		\
  TEST_SNPRINTF(EXP,  0,                __VA_ARGS__);		\
  TEST_SNPRINTF(EXP,  sizeof(EXP)+ALGN, __VA_ARGS__);		\
  TEST_SNPRINTF_NULL(EXP, __VA_ARGS__)
  

int main()
{
  char			cmp[ALGN];
  memset(cmp, '\376', sizeof cmp);

  TEST("x",   "x");
  TEST("xy",  "xy");


  TEST("23",       "%d", 23);
  TEST("5",        "%d", 5);
  TEST("0.05",     "%.2f", 0.05);
  TEST("0.000009", "%f", 9e-6);
  TEST("0.010000", "%f", 1e-2);
  TEST("    -1",   "%6d", -1);
  TEST("012",      "%03o", 10);

  TEST("foobar",  "%s",     "foobar");
  TEST("01.23",   "%05.2f", 1.23);
  TEST("001.2",   "%05.2g", 1.23);

  TEST("42",      "%i",     42);
  TEST("",        "%.0i",   0);

  TEST("52",      "%o",     42);
  TEST("",        "%.0o",   0);

  TEST("42",      "%u",     42);
  TEST("",        "%.0u",   0);

  TEST("2a",      "%x",     42);
  TEST("",        "%.0x",   0);

  TEST("2A",      "%X",     42);
  TEST("",        "%.0x",   0);

  TEST("42.23",   "%5.2f",  42.23);
  TEST("42.23",   "%5.4g",  42.23);
  TEST(" 42.2",   "%5.3g",  42.23);
  
  TEST("   1",     "%*i",   4, 1);
  TEST("   1",     "%4i",   1);
  TEST("1   ",     "%-4i",  1);
  TEST("  +1",     "%+4i",  1);
  TEST("+1  ",     "%-+4i", 1);
  TEST(" 1  ",     "%- 4i", 1);
  TEST("0001",     "%04i",  1);
  TEST("+001",     "%+04i", 1);

  TEST("0x1",      "%#x",   1);

  TEST("abcX",     "%2sX",  "abc");
  TEST("abcX",     "%-2sX", "abc");

  TEST("001234",   "%.6u",  1234);
  TEST("-001234",  "%.6i",  -1234);
  TEST("  1234",   "%6u",   1234);
  TEST(" -1234",   "%6i",   -1234);
  TEST("001234",   "%06u",  1234);
  TEST("-01234",   "%06i",  -1234);
  TEST("1234  ",   "%-6u",  1234);
  TEST("-1234 ",   "%-6i",  -1234);
  TEST("1234",     "%.6s",  "1234");
  TEST("  1234",   "%6s",   "1234");
  TEST("1234  ",   "%-6s",  "1234");
  TEST(" 01234",   "%6.5u", 1234);
  TEST("-01234",   "%6.5i", -1234);
  TEST("  1234",   "%6.5s", "1234");

#ifdef XSI_TESTS
  setlocale(LC_ALL, "de_DE");
  
  TEST("1.234",    "%'u", 1234);
  TEST("2 1",      "%2$u %1$u",  1, 2);
#endif
  
  
  return EXIT_SUCCESS;
}
