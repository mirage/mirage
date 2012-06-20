#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

int main() {
  char* p="/opt/diet/bin:/home/leitner/bin:/usr/local/bin:/opt/cross/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:/usr/sbin:/usr/X11R6/bin:/opt/teTeX/bin:/opt/qt-4.3.2/bin:/opt/kde-3.5/bin:/usr/X11R7/bin:/opt/mono/bin";
  assert(strchr(p,':')==p+13);
  assert(strchr(p="fnord",'\0')==p+5);
  assert(strchr(p,'r')==p+3);
  assert(strchr(p,'x')==0);
  return 0;
}
