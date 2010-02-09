#include <stdio.h>
#include <string.h>
#include <dietwarning.h>

char* ctermid(char* s) {
  static char name[L_ctermid];
  if (!s) s=name;
  return strcpy(s,"/dev/tty");
}

link_warning("ctermid","ctermid is obsolete junk, don't use!");
