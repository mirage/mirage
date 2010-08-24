#include <stdio.h>
#include <stdlib.h>
#include <strings.h>

void die(const char* message) {
  puts(message);
  exit(1);
}

int main() {
  char buf[100]="fNord";
  char buf2[100]="fnOrt";
  if (strcasecmp(buf,buf)) die("strcmp sais a != a");
  if (strcasecmp(buf,buf2)>=0) die("strcmp said fnord > fnort");
  if (strcasecmp(buf2,buf)<=0) die("strcmp said fnort < fnord");
  if (strcasecmp("Host","hostbasedauthentication")==0) die("strcmp said a == abc");
  return 0;
}
