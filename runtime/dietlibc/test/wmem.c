#include <wchar.h>
#include <assert.h>

int main() {
  wchar_t buf[100];
  int i;

  /* does wmemset work? */
  assert(wmemset(buf,0,100)==buf);
  for (i=0; i<100; ++i) assert(buf[i]==0);

  /* do wcscpy and wcscat work? */
  assert(wcscpy(buf,L"fnord")==buf);
  assert(wcscat(buf,L"blah")==buf);
  assert(wcslen(buf)==9);
  assert(wcscmp(buf,L"fnordblah")==0);

  /* does wmemcmp work? */
  assert(wmemcmp(buf,L"fnordxxx",5)==0);
  assert(wmemcmp(buf,L"fnordxxx",6)<0);

  /* check wmemcpy */
  assert(wmemcpy(buf+5,buf,5)==buf+5);
  assert(wmemcmp(buf,L"fnordfnord",10)==0);

  /* does wmemmove handle overlapping properly */
  assert(wmemmove(buf+1,buf,3)==buf+1);
  assert(wmemcmp(buf,L"ffnod",5)==0);
  assert(wmemmove(buf,buf+1,3)==buf);
  assert(wmemcmp(buf,L"fnood",5)==0);

  /* check wcsncpy */
  assert(wcsncpy(buf,L"fnord",8)==buf);
  assert(wmemcmp(buf,L"fnord\0\0\0",8)==0);
  buf[5]=L'x';
  assert(wcsncpy(buf,L"test_",5)==buf);
  assert(wmemcmp(buf,L"test_x\0\0",8)==0);

  /* check wcsncat */
  wmemset(buf,L'x',10);
  wcscpy(buf,L"ab");
  assert(wcsncat(buf,L"cd",5)==buf);	// normal case
  assert(wmemcmp(buf,L"abcd\0xxxxx",10)==0);
  assert(wcsncat(buf,L"efgh",2)==buf);	// truncation case
  assert(wmemcmp(buf,L"abcdef\0xxx",10)==0);

  /* wcsstr */
  wcscpy(buf,L"abracadabra");
  assert(wcsstr(buf,L"abr")==buf);
  assert(wcsstr(buf+1,L"abr")==buf+7);
  assert(wcsstr(buf+8,L"abr")==0);
}
