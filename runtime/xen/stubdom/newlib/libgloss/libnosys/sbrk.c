/* Version of sbrk for no operating system.  */

#include "config.h"
#include <_syslist.h>

void *
_sbrk (incr)
     int incr;
{ 
   extern char   end; /* Set by linker.  */
   static char * heap_end; 
   char *        prev_heap_end; 

   if (heap_end == 0)
     heap_end = & end; 

   prev_heap_end = heap_end; 
   heap_end += incr; 

   return (void *) prev_heap_end; 
} 
