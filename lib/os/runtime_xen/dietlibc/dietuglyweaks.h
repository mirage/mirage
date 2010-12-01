#ifndef __DIET_UGLY_WEAKS__
#define __DIET_UGLY_WEAKS__

/* if you change something here ... KNOW what you're doing !
 * it'll effect ALL platforms ! */

.macro DEF_G name
.global \name
.type \name,function
\name:
.endm
.macro DEF_W name
.weak \name
.type \name,function
\name:
.endm

DEF_W __fflush_stderr
DEF_W __fflush_stdin
DEF_W __fflush_stdout
DEF_W __nop
DEF_W __thread_doexit
DEF_W flockfile
DEF_W ftrylockfile
DEF_W funlockfile

DEF_G __you_tried_to_link_a_dietlibc_object_against_glibc

#endif
