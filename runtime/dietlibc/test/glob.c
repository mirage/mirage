#include <glob.h>
#include <stdio.h>

int main() {
  glob_t g;
  int i;
  printf("%d\n",glob("/tmp/*.c",0,0,&g));
  for (i=0; i<g.gl_pathc; ++i)
    printf("  %s\n",g.gl_pathv[i]);
return 0;    
}
