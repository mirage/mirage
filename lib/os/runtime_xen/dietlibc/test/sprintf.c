#include <string.h>
#include <stdio.h>
#include <assert.h>

int main() {
  char buf[1000];
  sprintf(buf,"%d",23);
  assert(!strcmp(buf,"23"));
  sprintf(buf,"%d",5);
  assert(!strcmp(buf,"5"));
  sprintf(buf,"%.2f", 0.05);
  assert(!strcmp(buf,"0.05"));
  sprintf(buf,"%f", 9e-6);
  assert(!strcmp(buf,"0.000009"));
  sprintf(buf,"%f", 1e-2);
  assert(!strcmp(buf,"0.010000"));
  sprintf(buf,"%6d",-1);
  assert(!strcmp(buf,"    -1"));
  strcpy(buf,"foo ");
  sprintf(buf+strlen(buf),"%s","bar ");
  strcat(buf,"baz.");
  assert(!strcmp(buf,"foo bar baz."));
  memset(buf,0,100);
  assert(snprintf(buf,1,"x")==1);
  assert(!strcmp(buf,""));
  assert(snprintf(buf,0,"x")==1);
  assert(!strcmp(buf,""));
  assert(sprintf(buf,"%03o",10)==3);
  assert(!strcmp(buf,"012"));
  return 0;
}
