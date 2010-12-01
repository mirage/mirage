#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <assert.h>

int main(int argc, char *argv[])
{
     char s[80];

     strncpy(s,"/usr/lib",80);       assert(strcmp(dirname(s),   "/usr")==0);
     strncpy(s,"/usr/",80);          assert(strcmp(dirname(s),   "/")==0);
     strncpy(s,"usr",80);            assert(strcmp(dirname(s),   ".")==0);
     strncpy(s,"usr/test",80);       assert(strcmp(dirname(s),   "usr")==0);
     strncpy(s,"usr/test/test2",80); assert(strcmp(dirname(s),   "usr/test")==0);
     strncpy(s,"/usr",80);           assert(strcmp(dirname(s),   "/")==0);
     strncpy(s,"/",80);              assert(strcmp(dirname(s),   "/")==0);
     strncpy(s,".",80);              assert(strcmp(dirname(s),   ".")==0);
     strncpy(s,"..",80);             assert(strcmp(dirname(s),   ".")==0);
     strncpy(s,"////",80);           assert(strcmp(dirname(s),   "/")==0);
     strncpy(s,"//",80);             assert(strcmp(dirname(s),   "/")==0);
                                     assert(strcmp(dirname(NULL),".")==0);
     s[0]=0;                         assert(strcmp(dirname(s),   ".")==0);

     puts("OK");
     return 0;
}
