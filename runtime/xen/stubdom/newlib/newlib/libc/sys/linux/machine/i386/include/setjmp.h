#define _JBLEN	9
typedef	long __jmp_buf[_JBLEN];

#define SP_INDEX 7
#define _JMPBUF_UNWINDS(buf, address) \
  ((void *)(address) < (void *)(buf)[SP_INDEX])
