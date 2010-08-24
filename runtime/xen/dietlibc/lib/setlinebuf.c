#include <stdio.h>
#include "dietwarning.h"
#undef setlinebuf

/* there is no previous prototype because it is a #define */
void setlinebuf(FILE* stream);

void setlinebuf(FILE* stream) {
  setvbuf(stream,0,_IOLBF,BUFSIZ);
}

link_warning("setlinebuf","warning: you used setlinebuf without including <stdio.h>")
