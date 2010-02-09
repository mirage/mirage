#ifdef __OD_CLEAN_ROOM

/* work around...
 * don't include <string.h> or <stdlib.h>
 */
#define _STRING_H
#define _STDLIB_H

/* we are the libdl.so so tell all included functiuons to be static. */
#define __DIET_LD_SO__

/*
 * this is the dietlibc libdl & dynamic-linker
 *
 * NEED to be compiled with -fPIC ...
 */
#include <sys/mman.h>
#include <sys/stat.h>
#include "_dl_int.h"
#include "_dl_rel.h"

void _start(void);	/* entry of lib... */

static void (*fini_entry)(void)=0;
static char **_dl_environ=0;
static unsigned long loadaddr=0;
static unsigned long prog_entry=0;

static Elf_Phdr*prog_ph;
static unsigned long prog_ph_size;
static unsigned long prog_ph_num;

static unsigned long at_uid;
static unsigned long at_euid;
static unsigned long at_gid;
static unsigned long at_egid;
static unsigned long at_pagesize;

/* this are the "local syscalls" */
__attribute__((noreturn,visibility("hidden")))
void _dl_sys_exit(int val);
__attribute__((visibility("hidden")))
int _dl_sys_read(int fd,void*buf,unsigned long len);
__attribute__((visibility("hidden")))
int _dl_sys_write(int fd,void*buf,unsigned long len);
__attribute__((visibility("hidden")))
int _dl_sys_open(const char*filename,int flags,int mode);
__attribute__((visibility("hidden")))
int _dl_sys_close(int fd);
__attribute__((visibility("hidden")))
void*_dl_sys_mmap(void*start,unsigned long length,int prot,int flags,int fd,unsigned long offset);
__attribute__((visibility("hidden")))
int _dl_sys_munmap(void*start,unsigned long length);
__attribute__((visibility("hidden")))
int _dl_sys_mprotect(const void*addr,unsigned long len,int prot);
__attribute__((visibility("hidden")))
int _dl_sys_fstat(int filedes, struct stat *buf);
__attribute__((visibility("hidden")))
void _dl_jump(void);

extern char*strdup(const char*s);
extern void free(void*p);

__attribute__((visibility("hidden")))
unsigned long _dl_main(int argc,char*argv[],char*envp[],unsigned long _dynamic);
__attribute__((visibility("hidden")))
unsigned long do_resolve(struct _dl_handle*dh,unsigned long off);

#if defined(__i386__)

asm(".text \n"
".type _start,@function \n"
"_start: \n"
"	movl	%esp, %ebp		# save stack \n"
"	movl	(%ebp), %ecx		# argc \n"
"	leal	4(%ebp), %esi		# argv \n"
"	leal	4(%esi,%ecx,4), %eax	# envp \n"
/* PIC code */
"	call	getpic \n"
"	addl	$_GLOBAL_OFFSET_TABLE_, %ebx \n"
/* for calculation of load addr, get 'relocated' address of _DYNAMIC */
"	leal	_DYNAMIC@GOTOFF(%ebx), %edx \n"
/* get load-address */
"	movl	%edx, %edi \n"
"	subl	(%ebx), %edi		# 'unrelocated' address of _DYNAMIC \n"
"	pushl	%edi \n"
/* put parameter on stack and call _dl_main */
"	pushl	%edx \n"
"	pushl	%eax \n"
"	pushl	%esi \n"
"	pushl	%ecx \n"
"	call	_dl_main \n"
/* restore stack */
"	movl	%ebp, %esp \n"
/* get fini pointer */
"	movl	fini_entry@GOTOFF(%ebx), %edx \n"
/* clear callee-save-register like kernel */
"	xorl	%ebx, %ebx \n"
"	xorl	%ebp, %ebp \n"
"	xorl	%edi, %edi \n"
"	xorl	%esi, %esi \n"
/* jump to program entry point */
"	jmp	*%eax \n"

".type	_dl_sys_read,@function \n"
"_dl_sys_read: \n"
"	movb	$3,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_write,@function \n"
"_dl_sys_write: \n"
"	movb	$4,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_open,@function \n"
"_dl_sys_open: \n"
"	movb	$5,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_close,@function \n"
"_dl_sys_close: \n"
"	movb	$6,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_mmap,@function \n"
"_dl_sys_mmap: \n"
"	movb	$90,%al \n"
"	leal	4(%esp),%edx \n"
"	pushl	%edx \n"
"	call	_dl_sys_call3 \n"
"	popl	%ecx \n"
"	ret \n"
".type	_dl_sys_munmap,@function \n"
"_dl_sys_munmap: \n"
"	movb	$91,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_fstat,@function \n"
"_dl_sys_fstat: \n"
"	movb	$108,%al \n"
"	jmp	_dl_sys_call3 \n"
".type	_dl_sys_mprotect,@function \n"
"_dl_sys_mprotect: \n"
"	movb	$125,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_exit,@function \n"
"_dl_sys_exit: \n"
"	movb	$1,%al \n"
".type	_dl_sys_call3,@function \n"
"_dl_sys_call3: \n"
"	movzbl	%al,%eax \n"
"	pushl	%ebx \n"
"	movl	%esp,%ebx \n"
"	movl	16(%ebx),%edx \n"
"	movl	12(%ebx),%ecx \n"
"	movl	8(%ebx),%ebx \n"
"	int	$0x80 \n"
"	popl	%ebx \n"
"	ret \n"

".type	_dl_jump,@function \n"
"_dl_jump: \n"
/* save temp-register (posible reg-args) */
"	pushl	%eax \n"
"	pushl	%ecx \n"
"	pushl	%edx \n"
/* call resolve */
"	push	16(%esp)	# 2. arg from plt \n"
"	push	16(%esp)	# 1. arg from plt \n"
"	call	do_resolve \n"
"	add	$8, %esp \n"
/* restore temp-register */
"	popl	%edx \n"
"	popl	%ecx \n"
"	xchgl	%eax, (%esp)	# restore eax and save function pointer (for return) \n"
"	ret	$8		# remove arguments from plt and jump to REAL function \n"

/* GET Position In Code :) */
"getpic:	movl	(%esp), %ebx \n"
"	ret");

static inline unsigned long* get_got(void) {
  register unsigned long *got asm ("%ebx");
  return got;
}

static inline int work_on_pltgot(struct _dl_handle*dh) {
  if ((dh->plt_rel)&&(!(dh->flags&RTLD_NOW))) {
    unsigned long*tmp=dh->pltgot;
    /* GOT */
    tmp[0]+=(unsigned long)dh->mem_base;	/* reloc dynamic pointer */
    tmp[1] =(unsigned long)dh;			/* the handle */
    tmp[2] =(unsigned long)(_dl_jump);		/* sysdep jump to do_resolve */
  }
  return 0;
}

#elif defined(__x86_64__)

#warning "x86_64 is not tested yet..."

asm(".text \n"
".type _start,@function \n"
"_start: \n"
"	movq	%rsp,%rbp		# save stack \n"
"	movq	(%rbp), %rdi		# argc \n"
"	leaq	8(%rbp),%rsi		# argv \n"
"	leaq	8(%rsi,%rdi,8),%rdx	# envp \n"
"	leaq	_DYNAMIC(%rip), %rcx	# relocated address of _DYNAMIC \n"
/* call _dl_main */
"	call	_dl_main \n"
/* restore stack */
"	movq	%rbp, %rsp \n"
/* get fini pointer */
"	movq	fini_entry(%rip), %rdx \n"
/* clear callee-save-register like kernel */
"	xorq	%rbp,%rbp \n"
/* jump to program entry point */
"	jmpq	*%rax \n"


".type _dl_sys_read,@function \n"
"_dl_sys_read: \n"
"	movb	$0,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_write,@function \n"
"_dl_sys_write: \n"
"	movb	$1,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_open,@function \n"
"_dl_sys_open: \n"
"	movb	$2,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_close,@function \n"
"_dl_sys_close: \n"
"	movb	$3,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_fstat,@function \n"
"_dl_sys_fstat: \n"
"	movb	$5,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_mmap,@function \n"
"_dl_sys_mmap: \n"
"	movb	$9,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_mprotect,@function \n"
"_dl_sys_mprotect: \n"
"	movb	$10,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_munmap,@function \n"
"_dl_sys_munmap: \n"
"	movb	$11,%al \n"
"	jmp	_dl_sys_call3 \n"
".type _dl_sys_exit,@function \n"
"_dl_sys_exit: \n"
"	movb	$60,%al \n"
".type _dl_sys_call3,@function \n"
"_dl_sys_call3: \n"
"	movzbq	%al,%rax \n"
"	movq	%rcx,%r10 \n"
"	syscall \n"
"	retq \n"

".type	_dl_jump,@function \n"
"_dl_jump: \n"
/* save register arguments */
"	pushq	%rax \n"
"	pushq	%rdi \n"
"	pushq	%rsi \n"
"	pushq	%rdx \n"
"	pushq	%rcx \n"
"	pushq	%r8 \n"
"	pushq	%r9 \n"
/* dynlib handle */
"	movq	56(%rsp),%rdi \n"
/* dyntab entry = 24*(index) */
"	movq	64(%rsp),%rsi \n"
"	leaq	(%rsi,%rsi,2),%rsi \n"
"	shlq	$3,%rsi \n"
/* call resolver */
"	call	do_resolve \n"
/* save return value */
"	movq	%rax,%r11 \n"
/* restore register args */
"	popq	%r9 \n"
"	popq	%r8 \n"
"	popq	%rcx \n"
"	popq	%rdx \n"
"	popq	%rsi \n"
"	popq	%rdi \n"
"	popq	%rax \n"
/* remove arguments from plt */
"	addq	$16,%rsp \n"
/* jump to REAL function */
"	jmpq	*%r11 \n"

   );

static inline unsigned long* get_got(void) {
  unsigned long*ret;
  asm("lea _GLOBAL_OFFSET_TABLE_(%%rip),%0" : "=r"(ret) );
  return ret;
}

static inline int work_on_pltgot(struct _dl_handle*dh) {
  if ((dh->plt_rel)&&(!(dh->flags&RTLD_NOW))) {
    unsigned long*tmp=dh->pltgot;
    /* GOT */
    tmp[0]+=(unsigned long)dh->mem_base;	/* reloc dynamic pointer */
    tmp[1] =(unsigned long)dh;			/* the handle */
    tmp[2] =(unsigned long)(_dl_jump);		/* sysdep jump to do_resolve */
  }
  return 0;
}

#elif defined(__arm__)

asm(".text \n"
".type _start,function \n"
"_start: \n"
/* common startup */
"	mov	r4, sp			@ save stack pointer \n"
"	mov	fp, #0			@ start new stack frame \n"
"	ldr	a1, [sp], #4		@ argc \n"
"	mov	a2, sp			@ argv \n"
"	mov	sp, r4			@ restore stack pointer \n"
"	add	a3, a2, a1, lsl #2	@ envp \n"
"	add	a3, a3, #4 \n"
/* PIC code startup */
"	ldr	sl, .L_got		@ PIC code \n"
"1:	add	sl, pc, sl \n"
/* get loadaddress */
"	ldr	a4, [sl] \n"
"	sub	a4, sl, a4 \n"
"	str	a4, [sp,#-4]! \n"
/* get 'relocated' address of _DYNAMIC */
"	ldr	a4, .L_dy \n"
"	add	a4, a4, sl \n"
/* call _dl_main */
"	bl	_dl_main \n"
/* save program entry point */
"	mov	lr, a1 \n"
/* abi: agrument 1: global fini entry */
"	ldr	a1, [pc, #.L_fe-(.+8)] \n"
"	ldr	a1, [sl, a1] \n"
/* jump to program entry point */
"	mov	pc, lr \n"
/* startup-code data */
".L_got: .long	_GLOBAL_OFFSET_TABLE_-(1b+8) \n"
".L_dy:	.long	_DYNAMIC(GOTOFF) \n"
".L_fe:	.long	fini_entry(GOTOFF) \n"

".type	_dl_sys_exit,function \n"
"_dl_sys_exit: \n"
"	swi	#0x900001		@ exit \n"
"	eor	pc, lr, lr		@ OR DIE ! \n"
"	mov	pc, lr \n"
".type	_dl_sys_read,function \n"
"_dl_sys_read: \n"
"	swi	#0x900003		@ read \n"
"	mov	pc, lr \n"
".type	_dl_sys_write,function \n"
"_dl_sys_write: \n"
"	swi	#0x900004		@ write \n"
"	mov	pc, lr \n"
".type	_dl_sys_open,function \n"
"_dl_sys_open: \n"
"	swi	#0x900005		@ open \n"
"	mov	pc, lr \n"
".type	_dl_sys_close,function \n"
"_dl_sys_close: \n"
"	swi	#0x900006		@ close \n"
"	mov	pc, lr \n"
".type	_dl_sys_mmap,function \n"
"_dl_sys_mmap: \n"
"	stmdb	sp!,{r0,r1,r2,r3} \n"
"	mov	r0, sp \n"
"	swi	#0x90005a		@ mmap \n"
"	add	sp, sp, #16 \n"
"	mov	pc, lr \n"
".type	_dl_sys_munmap,function \n"
"_dl_sys_munmap: \n"
"	swi	#0x90005b		@ munmap \n"
"	mov	pc, lr \n"
".type	_dl_sys_fstat,function \n"
"_dl_sys_fstat: \n"
"	swi	#0x90006c		@ fstat \n"
"	mov	pc, lr \n"
".type	_dl_sys_mprotect,function \n"
"_dl_sys_mprotect: \n"
"	swi	#0x90007d		@ mprotect \n"
"	mov	pc, lr \n"

".type	_dl_jump,function \n"
"_dl_jump: \n"
"	stmdb	sp!, {r0, r1, r2, r3}	@ save arguments \n"

"	sub	r1, ip, lr		@ dyntab entry \n"
"	sub	r1, r1, #4 \n"
"	add	r1, r1, r1 \n"

"	ldr	r0, [lr, #-4]		@ dynlib handle \n"

"	bl	do_resolve \n"

"	mov	r12, r0 \n"
"	ldmia	sp!, {r0, r1, r2, r3, lr} @ restore arguments \n"
"	mov	pc, r12");

static inline unsigned long* get_got(void) {
  register unsigned long *got asm ("sl");
  return got;
}

static inline int work_on_pltgot(struct _dl_handle*dh) {
  if ((dh->plt_rel)&&(!(dh->flags&RTLD_NOW))) {
    unsigned long*tmp=dh->pltgot;
    /* GOT */
    tmp[0]+=(unsigned long)dh->mem_base;	/* reloc dynamic pointer */
    tmp[1] =(unsigned long)dh;			/* the handle */
    tmp[2] =(unsigned long)(_dl_jump);		/* sysdep jump to do_resolve */
  }
  return 0;
}

#elif defined(__sparc__)

#warning "sparc is not working !!! AND HAS NO RESOLVER !!!"

/* ARG... sparc has EVERY variable (even static) only addressable through the GOT */

asm(".text \n"
".align 16 \n"
".global _start \n"
".hidden _start \n"
".type _start,@function \n"
"_start: \n"
/* save some later needed values */
"	mov	%sp, %l0 \n"
"	mov	%g1, %l1 \n"
/* close frame / make room for some arguments */
"	mov	%g0, %fp \n"
"	sub	%sp, 6*4, %sp \n"
/* extrace argc(%o0), argv(%o1), envp(%o2) */
"	ld	[%sp+22*4], %o0 \n"
"	add	%sp, 23*4, %o1 \n"
"	add	%o1, %o0, %o2 \n"
"	add	%o2, %o0, %o2 \n"
"	add	%o2, %o0, %o2 \n"
"	add	%o2, %o0, %o2 \n"
"	add	%o2, 4, %o2 \n"
/* PIC code / startup */
"	sethi	%hi(_GLOBAL_OFFSET_TABLE_-4), %l7 \n"
".L0:	call	.L1 \n"
"	add	%l7, %lo(_GLOBAL_OFFSET_TABLE_+4), %l7 \n"
".L1:	add	%o7, %l7, %l7 \n"
/* get load-address (%o4) */
"	sethi	%hi(.L0), %o4 \n"
"	add	%o4, %lo(.L0), %o4 \n"
"	ld	[ %l7 + %o4 ], %o4 \n"
"	sub	%o7, %o4, %o4 \n"
/* get 'relocated' address of _DYNAMIC (%o3) // call the dynamic linker */
"	ld	[ %l7 ], %o3 \n"
//"	call	_dl_main \n"
"	call	_pr_ping \n"
"	add	%o4, %o3, %o3 \n"
/* put entry point to the return register */
"	mov	%o0, %o7 \n"
/* restore some values // 'jump' to entry point */
"	mov	%l1, %g1 \n"
"	retl \n"
"	mov	%l0, %sp \n"

"_pr_ping_str: \n"
"	.asciz \"ping.\\n\" \n"
".align 4 \n"
"_pr_ping: \n"
"	save \n"
"1:	call	1f \n"
"	mov	_pr_ping_str-1b, %i1 \n"
"1:	add	%o7, %i1, %i1 \n"
"	restore \n"
"	mov	6, %o2 \n"
"	call	_dl_sys_write \n"
"	mov	2, %o0 \n"
"	call	_dl_sys_exit \n"
"	mov	0, %o0 \n"


".type _dl_sys_exit,@function \n"
"_dl_sys_exit: \n"
"	mov	1, %g1 \n"
".type _dl_sys_call3,@function \n"
"_dl_sys_call3: \n"
"	ta	0x10 \n"
"	retl \n"
"	nop \n"
".type _dl_sys_read,@function \n"
"_dl_sys_read: \n"
"	b	_dl_sys_call3 \n"
"	mov	3, %g1 \n"
".type _dl_sys_write,@function \n"
"_dl_sys_write: \n"
"	b	_dl_sys_call3 \n"
"	mov	4, %g1 \n"
".type _dl_sys_open,@function \n"
"_dl_sys_open: \n"
"	b	_dl_sys_call3 \n"
"	mov	5, %g1 \n"
".type _dl_sys_close,@function \n"
"_dl_sys_close: \n"
"	b	_dl_sys_call3 \n"
"	mov	6, %g1 \n"
".type _dl_sys_mmap,@function \n"
"_dl_sys_mmap: \n"
"	b	_dl_sys_call3 \n"
"	mov	71, %g1 \n"
".type _dl_sys_munmap,@function \n"
"_dl_sys_munmap: \n"
"	b	_dl_sys_call3 \n"
"	mov	73, %g1 \n"
".type _dl_sys_fstat,@function \n"
"_dl_sys_fstat: \n"
"	b	_dl_sys_call3 \n"
"	mov	62, %g1 \n"
".type _dl_sys_mprotect,@function \n"
"_dl_sys_mprotect: \n"
"	b	_dl_sys_call3 \n"
"	mov	74, %g1 \n"

".type	_dl_jump,@function \n"
"_dl_jump: \n"
"	ret \n"
   );

static inline unsigned long* get_got(void) {
  register unsigned long *got asm ("%l7");
  return got;
}

static inline int work_on_pltgot(struct _dl_handle*dh) {
  if ((dh->plt_rel)&&(!(dh->flags&RTLD_NOW))) {
    unsigned long*tmp=dh->pltgot;
    /* GOT */
    tmp[0]+=(unsigned long)dh->mem_base;	/* reloc dynamic pointer */
    tmp[1] =(unsigned long)dh;			/* the handle */
    tmp[2] =(unsigned long)(_dl_jump);		/* sysdep jump to do_resolve */
  }
  return 0;
}
#else
#error "libdl: arch not supported"
#endif

static void*_dl_load(const char*fn,const char*pathname,int fd,int flags);

/* here do the code includes */

/* strncpy */
static char*_dl_lib_strncpy(register char*s,register const char*t,register unsigned long n) {
  char *dest=s;
  for(;n;--n) {
    char ch=*t;
    *s=ch;
    if (ch==0) return dest;
    ++s; ++t;
  }
  return 0;
}

/* strlen.c */
static unsigned long _dl_lib_strlen(register const char*s) {
  register unsigned long i;
  if (!s) return 0;
  for (i=0; *s; ++s) ++i;
  return i;
}

/* strcmp.c */
static int _dl_lib_strcmp(register const unsigned char*s,register const unsigned char*t) {
  register char x;
  for (;;) {
    x = *s; if (x != *t) break; if (!x) break; ++s; ++t;
  }
  return ((int)(unsigned int)x) - ((int)(unsigned int)*t);
}

/* strcspn.c */
static unsigned long _dl_lib_strcspn(const char*s,const char*reject) {
  unsigned long l=0;
  int a=1,i,al=_dl_lib_strlen(reject);
  while((a)&&(*s)) {
    for(i=0;(a)&&(i<al);++i) if (*s==reject[i]) a=0;
    if (a) ++l;
    ++s;
  }
  return l;
}

/* memcpy.c */
static void*_dl_lib_memcpy(void*dst,const void*src,unsigned long count) {
  register char *d=dst;
  register const char *s=src;
  ++count;
  while (--count) {
    *d = *s;
    ++d; ++s;
  }
  return dst;
}

/* memset.c */
static void*_dl_lib_memset(void*dst,int ch,unsigned long count) {
  register char *d=dst;
  ++count;
  while (--count) {
    *d=ch;
    ++d;
  }
  return dst;
}

/* memcmp.c */
static int _dl_lib_memcmp(register const unsigned char*s,register const unsigned char*t,unsigned long count) {
  register int r;
  ++count;
  while(--count) {
    if ((r=(*s-*t))) return r;
    ++s;
    ++t;
  }
  return 0;
}

/* getenv.c */
static char*getenv(const char*env) {
  unsigned int i,len=_dl_lib_strlen(env);
  for (i=0;_dl_environ[i];++i) {
    if ((_dl_lib_memcmp((const unsigned char*)_dl_environ[i],(const unsigned char*)env,len)==0) && (_dl_environ[i][len]=='='))
      return _dl_environ[i]+len+1;
  }
  return 0;
}

/* basic debug output functions */
static void pf(const char*s) { _dl_sys_write(2,(void*)s,_dl_lib_strlen(s)); }
static void ph(unsigned long l) {
  const int max=(sizeof(unsigned long)<<1);
  unsigned char buf[16];
  int i;
  for (i=max;i;l>>=4) {
    register unsigned long v='0'|(l&15);
    if (v>'9') v+=0x27;
    buf[--i]=v;
  }
  _dl_sys_write(2,buf,max);
}

/* the never free strdup (internal) */
static unsigned long _dl_lib_strdup_len=0;
static char*_dl_lib_strdup_str;
static char*_dl_lib_strdup(const char*s) {
  char*ret=_dl_lib_strdup_str;
  unsigned long l=_dl_lib_strlen(s)+1;
  if (_dl_lib_strdup_len<l) {
    ret=(char*)_dl_sys_mmap(0,at_pagesize,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    _dl_lib_strdup_len=at_pagesize;
  }
  _dl_lib_strdup_str=ret+l;
  _dl_lib_strdup_len-=l;
  _dl_lib_memcpy(ret,s,l);
  return ret;
}

#ifdef WANT_LD_SO_GDB_SUPPORT
/* gdb debug init stuff */
static struct r_debug _r_debug;

/* gdb debug break point */
__attribute__((used,noinline))
static void _dl_debug_state(void) {
#ifdef DEBUG
  struct _dl_handle*tmp;
  pf(__FUNCTION__); pf(": r_state "); ph(_r_debug.r_state); pf("\n");
  for (tmp=_r_debug.r_map;tmp;tmp=tmp->next) {
    pf("link_map "); ph((unsigned long)tmp);
    pf(" l_addr "); ph((unsigned long)tmp->mem_base);
    pf(" l_name "); pf(tmp->l_name ? tmp->l_name : "<null>");
    pf(" l_ld "); ph((unsigned long)tmp->dynamic); pf("\n");
  }
#endif
}
#endif

/* now reuse some unchanged sources */
#ifdef __arm__
#include "_dl_math.c"
#define MOD(a,b) _dl_mod(a,b)
#define DIV(a,b) _dl_div(a,b,NULL)
#else
#define MOD(a,b) (a % b)
#define DIV(a,b) (a / b)
#endif

#include "dlerror.c"
#include "_dl_alloc.c"

#include "dlsym.c"
#include "dladdr.c"

#include "_dl_search.c"

#include "_dl_open.c"
#include "dlopen.c"

#include "_dl_relocate.c"
#include "_dl_queue.c"

#include "dlclose.c"

/* back to the "new" implementation */
static void tt_fini(void) {
  struct _dl_handle*tmp;
#ifdef DEBUG
  pf("dyn fini\n");
#endif
  for(tmp=_dl_root_handle;tmp;tmp=tmp->next)
    if (tmp->fini) tmp->fini();
}

/* exit ! */
__attribute__((noreturn))
static void _DIE_() { _dl_sys_exit(213); }

/* lazy function resolver */
unsigned long do_resolve(struct _dl_handle*dh,unsigned long off) {
  _dl_rel_t *tmp = ((void*)dh->plt_rel)+off;
  int sym=ELF_R_SYM(tmp->r_info);
  register unsigned long sym_val;

  if (0) sym_val=(unsigned long)do_resolve; /* TRICK: no warning */

  /* modify GOT for REAL symbol */
  sym_val=(unsigned long)_dl_sym(dh,sym);
  *((unsigned long*)(dh->mem_base+tmp->r_offset))=sym_val;

  /* JUMP (arg sysdep...) */
  if (sym_val) return sym_val;
  /* can't find symbol */
  return (unsigned long)_DIE_;
}

/* library loader */

/* ELF -> MMAP permissions */
static inline int map_flags(int flags) {
  int perm = 0;
  if (flags & PF_X) perm|=PROT_EXEC;
  if (flags & PF_R) perm|=PROT_READ;
  if (flags & PF_W) perm|=PROT_WRITE;
  return perm;
}

/* a simple mmap wrapper */
static inline void*do_map_in(void*base,unsigned long length,int flags,int fd,unsigned long offset) {
  register int op = MAP_PRIVATE;
  if (base) op|=MAP_FIXED;
  return _dl_sys_mmap(base, length, map_flags(flags), op, fd, offset);
}

/* map a library into memory */
#define _ELF_DWN_ROUND(ps,n)	((n)&(~((ps)-1)))
#define _ELF_UP_ROUND(ps,n)	((((n)&((ps)-1))?(ps):0)+_ELF_DWN_ROUND((ps),(n)))
#define _ELF_RST_ROUND(ps,n)	((n)&((ps)-1))
static struct _dl_handle*_dl_map_lib(const char*fn,const char*pathname,int fd,int flags) {
  struct _dl_handle*ret=0;
  int i;
  unsigned char buf[1024];
  char *m=0,*d=0;

  unsigned long l;
  struct stat st;

  Elf_Ehdr*eeh;
  Elf_Phdr*eph;

  int ld_nr=0;
  Elf_Phdr*ld[4];
  Elf_Phdr*dyn=0;

  _dl_lib_memset(ld,0,sizeof(ld));

  if (fd==-1) return 0;

  if (_dl_sys_fstat(fd,&st)<0) {
err_out_close:
    _dl_sys_close(fd);
    _dl_error_data=fn;
    _dl_error=2;
    return 0;
  } else {
    /* use st_dev and st_ino for identification */
  }

  if (_dl_sys_read(fd,buf,1024)<128) goto err_out_close;

  eeh=(Elf_Ehdr*)buf;
  eph=(Elf_Phdr*)&buf[eeh->e_phoff];

  for (i=0;i<eeh->e_phnum;++i) {
    if (eph[i].p_type==PT_LOAD) {
      if (ld_nr>3) goto err_out_close;
      ld[ld_nr++]=eph+i;
    }
    if (eph[i].p_type==PT_DYNAMIC) {
      dyn=eph+i;
    }
  }

  if (ld_nr==1) {
    unsigned long addr  =_ELF_DWN_ROUND(at_pagesize,ld[0]->p_vaddr);
    unsigned long offset=_ELF_DWN_ROUND(at_pagesize,ld[0]->p_offset);
    unsigned long off   =_ELF_RST_ROUND(at_pagesize,ld[0]->p_offset);
    unsigned long length=_ELF_UP_ROUND(at_pagesize,ld[0]->p_memsz+off);
    ret=_dl_get_handle();
    m=(char*)do_map_in((void*)addr,length,ld[0]->p_flags,fd,offset);
    if (m==MAP_FAILED) goto err_out_free;
    /* zero pad bss */
    l=ld[0]->p_offset+ld[0]->p_filesz;
    _dl_lib_memset(m+l,0,length-l);

    ret->mem_base=m;
    ret->mem_size=length;
  }
  else if (ld_nr==2) { /* aem... yes Quick & Really Dirty / for the avarage 99% */
    unsigned long text_addr = _ELF_DWN_ROUND(at_pagesize,ld[0]->p_vaddr);
    unsigned long text_offset=_ELF_DWN_ROUND(at_pagesize,ld[0]->p_offset);
    unsigned long text_off   =_ELF_RST_ROUND(at_pagesize,ld[0]->p_offset);
    unsigned long text_size  =_ELF_UP_ROUND(at_pagesize,ld[0]->p_memsz+text_off);

    unsigned long data_addr  =_ELF_DWN_ROUND(at_pagesize,ld[1]->p_vaddr);
    unsigned long data_offset=_ELF_DWN_ROUND(at_pagesize,ld[1]->p_offset);
    unsigned long data_off   =_ELF_RST_ROUND(at_pagesize,ld[1]->p_offset);
    unsigned long data_size  =_ELF_UP_ROUND(at_pagesize,ld[1]->p_memsz+data_off);
    unsigned long data_fsize =_ELF_UP_ROUND(at_pagesize,ld[1]->p_filesz+data_off);

    /* handle data_addr relative to text_addr */
    data_addr-=text_addr;

    ret=_dl_get_handle();
    /* mmap all mem_blocks for *.so */
    m=(char*)do_map_in((void*)text_addr,text_size+data_size,ld[0]->p_flags,fd,text_offset);
    if (m==MAP_FAILED) {
err_out_free:
      _dl_free_handle(ret);
      _dl_sys_close(fd);
      return 0;
    }
    /* are we loaded where we wanna be ? */
    if (text_addr && (m!=(void*)text_addr)) {
      _dl_sys_munmap(m,text_size+data_size);
      goto err_out_free;
    }

    /* release data,bss part */
    _dl_sys_mprotect(m+data_addr,data_size,PROT_NONE);

    /* mmap data,bss part */
    d=(char*)do_map_in(m+data_addr,data_fsize,ld[1]->p_flags,fd,data_offset);

    /* zero pad bss */
    l=data_off+ld[1]->p_filesz;
    _dl_lib_memset(d+l,0,data_fsize-l);
    /* more bss ? */
    if (data_size>data_fsize) {
      l=data_size-data_fsize;
      _dl_sys_mmap(d+data_fsize,l,PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS,-1,0);
    }

    ret->mem_base=m;
    ret->mem_size=text_size+data_size;
  }
  else {
    _dl_error_data=fn;
    _dl_error=7;
  }

  if (ret) {
    ++ret->lnk_count;
    if (flags&RTLD_USER) {
      ret->l_name=strdup(pathname);
      ret->name=strdup(fn);
    } else {
      ret->l_name=_dl_lib_strdup(pathname);
      ret->name=_dl_lib_strdup(fn);
    }
    ret->flags=flags;
    ret->dynamic=(Elf_Dyn*)(m+dyn->p_vaddr);
  }

  _dl_sys_close(fd);
  return ret;
}

/* dynamic section parser */
static struct _dl_handle* _dl_dyn_scan(struct _dl_handle*dh,Elf_Dyn*_dynamic) {
  void(*init)(void)=0;

  _dl_rel_t* plt_rel=0;
  unsigned long  plt_relsz=0;

  _dl_rel_t* rel=0;
  unsigned long relent=0;
  unsigned long relsize=0;

  int i;

#ifdef DEBUG
  pf(__FUNCTION__); pf(": pre dynamic scan "); ph((unsigned long)dh); pf("\n");
#endif
  for(i=0;_dynamic[i].d_tag;++i) {
    switch(_dynamic[i].d_tag) {
      /* this depends on dyn_str_tab -> second run */
    case DT_NEEDED:
    case DT_SONAME:
      break;

      /* BASIC DYNAMIC STUFF */
    case DT_HASH:
      dh->hash_tab = (unsigned int*)(dh->mem_base+_dynamic[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have hash @ "); ph((long)dh->hash_tab); pf("\n");
#endif
      break;
    case DT_SYMTAB:
      dh->dyn_sym_tab = (Elf_Sym*)(dh->mem_base+_dynamic[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have dyn_sym_tab @ "); ph((long)dh->dyn_sym_tab); pf("\n");
#endif
      break;
    case DT_STRTAB:
      dh->dyn_str_tab = (char*)(dh->mem_base+_dynamic[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have dyn_str_tab @ "); ph((long)dh->dyn_str_tab); pf("\n");
#endif
      break;
    case DT_GNU_HASH:
      dh->gnu_hash_tab = (unsigned int*)(dh->mem_base+_dynamic[i].d_un.d_ptr);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have GNU-hash @ "); ph((long)dh->gnu_hash_tab); pf("\n");
#endif
      break;

      /* DYNAMIC INIT/FINI (constructors/destructors) */
    case DT_FINI:
      dh->fini = (void(*)(void))(dh->mem_base+_dynamic[i].d_un.d_val);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have fini @ "); ph((long)dh->fini); pf("\n");
#endif
      break;
    case DT_INIT:
      init = (void(*)(void))(dh->mem_base+_dynamic[i].d_un.d_val);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have init @ "); ph((long)init); pf("\n");
#endif
      break;

      /* PLT RELOCATION */
    case DT_PLTGOT:
      dh->pltgot = (unsigned long*)(dh->mem_base+_dynamic[i].d_un.d_val);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have plt/got @ "); ph((long)dh->pltgot); pf("\n");
#endif
      break;
    case DT_PLTREL:
      if (_dynamic[i].d_un.d_val!=_DL_REL_T) {
#ifdef DEBUG
	pf(__FUNCTION__); pf(": have incompatible relocation type\n");
#endif
	_dl_error_data=dh->name;
	_dl_error=6;
	return 0;
      }
      break;
    case DT_JMPREL:
      plt_rel = (_dl_rel_t*)(dh->mem_base+_dynamic[i].d_un.d_val);
      dh->plt_rel = plt_rel;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have jmprel @ "); ph((long)plt_rel); pf("\n");
#endif
      break;
    case DT_PLTRELSZ:
      plt_relsz = _dynamic[i].d_un.d_val;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have pltrelsize @ "); ph((long)plt_relsz); pf("\n");
#endif
      break;

      /* BASIC RELOCATION */
    case DT_REL:
    case DT_RELA:
      rel = (_dl_rel_t*)(dh->mem_base+_dynamic[i].d_un.d_val);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have rel @ "); ph((long)rel); pf("\n");
#endif
      break;
    case DT_RELENT:
    case DT_RELAENT:
      relent=_dynamic[i].d_un.d_val;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have relent  @ "); ph((long)relent); pf("\n");
#endif
      break;
    case DT_RELSZ:
    case DT_RELASZ:
      relsize=_dynamic[i].d_un.d_val;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": have relsize @ "); ph((long)relsize); pf("\n");
#endif
      break;


      /* TEXT RELOCATIONS POSSIBLE -> NO SHARED OBJECT */
    case DT_TEXTREL:
#ifdef DEBUG
      pf(__FUNCTION__); pf(": found possible textrelocation -> "); pf(dh->name); pf(" is not compiled as a shared library\n");
#endif
      _dl_error_data=dh->name;
      _dl_error=3;
      return 0;
      break;

      /* OTHERS */
    default:
#ifdef DEBUG
#if 0
      pf(__FUNCTION__); pf(": unknown "); ph(_dynamic[i].d_tag); pf(", "); ph(_dynamic[i].d_un.d_val); pf("\n");
#endif
#endif
      break;
    }
  }

  for(i=0;_dynamic[i].d_tag;i++) {
    if (dh->name) {	/* librabry can have a SONAME */
      if (_dynamic[i].d_tag==DT_SONAME) {
#ifdef DEBUG
	pf(__FUNCTION__); pf(": pre  soname: "); pf(dh->name); pf("\n");
#endif
	if (dh->flags&RTLD_USER) free(dh->name);
	dh->flags&=~RTLD_NOSONAME;
	dh->name = dh->dyn_str_tab+_dynamic[i].d_un.d_val;
#ifdef DEBUG
	pf(__FUNCTION__); pf(": have soname: "); pf(dh->name); pf("\n");
#endif
      }
    }
    else {		/* programs can have a LD_RUN_PATH */
      if (_dynamic[i].d_tag==DT_RPATH) {
	register char *rpath=dh->dyn_str_tab+_dynamic[i].d_un.d_val;
	_dl_search_rpath=rpath;
#ifdef DEBUG
	pf(__FUNCTION__); pf(": have runpath: "); pf(rpath); pf("\n");
#endif
      }
    }
  }

#ifdef DEBUG
  pf(__FUNCTION__); pf(": post dynamic scan "); ph((unsigned long)dh); pf("\n");
#endif

  if (work_on_pltgot(dh)) {
    _dl_error_data=dh->name;
    _dl_error=3;
    return 0;
  }

#ifdef DEBUG
  pf(__FUNCTION__); pf(": pre load depending libraries "); ph((unsigned long)dh); pf("\n");
#endif
  /* load depending libs */
  for(i=0;_dynamic[i].d_tag;++i) {
    if (_dynamic[i].d_tag==DT_NEEDED) {
      char *lib_name=dh->dyn_str_tab+_dynamic[i].d_un.d_val;
#ifdef DEBUG
      pf(__FUNCTION__); pf(": needed for this lib: "); pf(lib_name); pf("\n");
#endif
      _dl_queue_lib(lib_name,dh->flags);
    }
  }
#ifdef DEBUG
  pf(__FUNCTION__); pf(": pre open depending libraries 2 "); ph((unsigned long)dh); pf("\n");
#endif
  if (_dl_open_dep()) {
    return 0;
  }

#ifdef DEBUG
  pf(__FUNCTION__); pf(": post load depending libraries, pre resolve "); ph((unsigned long)dh); pf("\n");
#endif

  /* relocation */
  if (rel) {
#ifdef DEBUG
    pf(__FUNCTION__); pf(": try to relocate some values\n");
#endif
    if (_dl_relocate(dh,rel,DIV(relsize,relent))) return 0;
  }

  /* do PTL / GOT relocation */
  if (plt_rel) {
    _dl_rel_t *tmp,*max=((void*)plt_rel)+plt_relsz;
#ifdef DEBUG
    pf(__FUNCTION__); pf(": rel plt/got\n");
#endif
    for(tmp=plt_rel;tmp<max;tmp=(void*)(((char*)tmp)+sizeof(_dl_rel_t))) {
      if ((dh->flags&RTLD_NOW)) {
	unsigned long sym=(unsigned long)_dl_sym(dh,ELF_R_SYM(tmp->r_info));
	if (sym) *((unsigned long*)(dh->mem_base+tmp->r_offset))=sym;
	else {
	  _dl_error_data=dh->name;
	  _dl_error=4;
	  return 0;
	}
      }
      else
	_DL_REL_PLT(dh->mem_base,tmp);
#ifdef DEBUG
      pf(__FUNCTION__); pf(": rel @ "); ph((long)dh->mem_base+tmp->r_offset); pf(" with type ");
      ph(ELF_R_TYPE(tmp->r_info)); pf(" and sym "); ph(ELF_R_SYM(tmp->r_info));
      pf(" -> "); ph(*((unsigned long*)(dh->mem_base+tmp->r_offset))); pf("\n");
#endif
    }
  }

#ifdef DEBUG
  pf(__FUNCTION__); pf(": post resolve, pre init "); ph((unsigned long)dh); pf("\n");
#endif
  if (init) init();
#ifdef DEBUG
  pf(__FUNCTION__); pf(": post init "); ph((unsigned long)dh); pf("\n");
#endif

  return dh;
}

static void*_dl_load(const char*fn,const char*pathname,int fd,int flags) {
  struct _dl_handle*ret=0;
  if ((ret=_dl_map_lib(fn,pathname,fd,flags))) {
    ret=_dl_dyn_scan(ret,ret->dynamic);
#ifdef WANT_LD_SO_GDB_SUPPORT
    if (ret) {
      _r_debug.r_state=RT_ADD;
      _dl_debug_state();
      _r_debug.r_state=RT_CONSISTENT;
      _dl_debug_state();
    }
#endif
  }
  return ret;
}


/* ELF AUX parser */
static void _dl_elfaux(register unsigned long*ui) {
  register struct elf_aux {
    unsigned long type;
    unsigned long val;
  } *ea;

  while (*ui) ++ui;
  /* now *ui points to the tailing NULL-pointer of the envirioment */

  /* walk the elf_aux table */
  for (ea=(struct elf_aux*)(ui+1); ea->type; ++ea) {
    switch (ea->type) {
    case AT_EXECFD:	/* 2 */
      /* DIE! DIE! DIE! */
      pf("kernel gives us an unsupported binary load type...\n");
      _dl_sys_exit(42);
      break;

    case AT_PHDR:	/* 3 */
      prog_ph=(Elf_Phdr*)ea->val;
#ifdef DEBUG
      pf("program header @ "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_PHENT:	/* 4 */
      prog_ph_size=ea->val;
#ifdef DEBUG
      pf("program header size "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_PHNUM:	/* 5 */
      prog_ph_num=ea->val;
#ifdef DEBUG
      pf("program header # "); ph(ea->val); pf("\n");
#endif
      break;

    case AT_PAGESZ:	/* 6 */
      at_pagesize=ea->val;
#ifdef DEBUG
      pf("page size "); ph(ea->val); pf("\n");
#endif
      break;

    case AT_BASE:	/* 7 */
      loadaddr=ea->val;
#ifdef DEBUG
      pf("interpreter base: "); ph(ea->val); pf("\n");
#endif
      break;

#if 0
    case AT_FLAGS:	/* 8 */
#ifdef DEBUG
      pf("flags "); ph(ea->val); pf("\n");
#endif
      break;
#endif

    case AT_ENTRY:	/* 9 */
      prog_entry=ea->val;
#ifdef DEBUG
      pf("start program  @ "); ph(ea->val); pf("\n");
#endif
      break;

    case AT_NOTELF:	/* 10 */
      pf("this is an ELF-loader... and therefor can't handle anything else.\n");
      _dl_sys_exit(42);
      break;

    case AT_UID:	/* 11 */
      at_uid=ea->val;
#ifdef DEBUG
      pf(" UID: "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_EUID:	/* 12 */
      at_euid=ea->val;
#ifdef DEBUG
      pf("EUID: "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_GID:	/* 13 */
      at_gid=ea->val;
#ifdef DEBUG
      pf(" GID: "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_EGID:	/* 14 */
      at_egid=ea->val;
#ifdef DEBUG
      pf("EGID: "); ph(ea->val); pf("\n");
#endif
      break;

#if 0
    case AT_PLATFORM:	/* 15 */
#ifdef DEBUG
      pf("CPU: "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_HWCAP:	/* 16 */
#ifdef DEBUG
      pf("CPU capabilities: "); ph(ea->val); pf("\n");
#endif
      break;
    case AT_CLKTCK:	/* 17 */
#ifdef DEBUG
      pf("CLK per sec "); ph( ea->val); pf("\n");
#endif
      break;
    case AT_FPUCW:	/* 18 */
#ifdef DEBUG
      pf("FPU control word "); ph( ea->val); pf("\n");
#endif
      break;
#endif

    case AT_SYSINFO:
      /* TODO: rewrite unified syscall to use this value */

    default:
      break;
    }
  }
}


/* start of libdl dynamic linker */
unsigned long _dl_main(int argc,char*argv[],char*envp[],unsigned long _dynamic) {
  unsigned long*got;
  struct _dl_handle*prog,*mydh;
  struct _dl_handle my_dh;
  Elf_Dyn*prog_dynamic=0;
  unsigned int i;

  if (0) _dl_main(argc,argv,envp,_dynamic); /* TRICK: no warning */

  /* prepare to bootstarp the relocations */
  got=get_got();
  _dl_environ=envp;

  /* run elf_aux (kernel provided misc data) */
  _dl_elfaux((unsigned long*)envp);

  if (loadaddr==0) {
    pf("\ndiet libdl.so/dynamic-linker can't be started as a program !\n\n SORRY...\n\n");
    return (unsigned long)_DIE_;
  }

  _dl_lib_memset(&my_dh,0,sizeof(my_dh));
  my_dh.mem_base=(char*)loadaddr;
  my_dh.mem_size=0;
  my_dh.lnk_count=1024;
  my_dh.l_name=0; /* filled in later from PT_INTERP */
  my_dh.name="libdl.so";
  my_dh.flags=LDSO_FLAGS;

  got[1]=0;			/* NOT YET (my_dh) */
  got[2]=(unsigned long)_DIE_;	/* NO lazy symbol resolver as long as we are not ready */

#ifdef DEBUG
  pf(__FUNCTION__); pf(": pre scan\n");
#endif
  /* bootstrap relocation */
  if (_dl_dyn_scan(&my_dh,(Elf_Dyn*)_dynamic)==0) {
    pf("error with dyn_scan myself\n");
    return (unsigned long)_DIE_;
  }
#ifdef DEBUG
  pf(__FUNCTION__); pf(": post scan\n");
#endif

  /* now we are save to use anything :) (hopefully) */

  fini_entry=tt_fini;

  prog=_dl_get_handle();

#ifdef DEBUG
  pf(__FUNCTION__); pf(": ugly, ugly, COPY pregenerated handle to real handle\n");
#endif
  mydh=_dl_get_handle();
  {
    register struct _dl_handle*tmp=mydh->prev;
    _dl_lib_memcpy(mydh,&my_dh,sizeof(struct _dl_handle));
    mydh->prev=tmp;
  }
  got[1]=(unsigned long)mydh;

#ifdef DEBUG
  pf(__FUNCTION__); pf(": MORE ugly: prepare program...\n");
#endif
  for(i=0;(i<prog_ph_num);++i) {
    if (prog_ph[i].p_type==PT_DYNAMIC) {
      prog_dynamic=(Elf_Dyn*)prog_ph[i].p_vaddr;
    }
    if (prog_ph[i].p_type==PT_INTERP) {
      mydh->l_name=(char*)prog_ph[i].p_vaddr;
    }
  }
  if (prog_dynamic==0) {
    ph(0xe0000001);
    pf(" error with program: no dynamic section ?\n");
    return (unsigned long)_DIE_;
  }
  prog->l_name=0;
  prog->name=0;
  prog->lnk_count=1024;
  prog->dynamic=prog_dynamic;
  prog->flags=LDSO_FLAGS;

#ifdef DEBUG
  pf(__FUNCTION__); pf(": dyn_scan program...\n");
#endif
  if (_dl_dyn_scan(prog,(Elf_Dyn*)prog_dynamic)==0) {
    _dl_error_location="error in dyn_scan the program";
    pf(dlerror()); pf("\n");
    return (unsigned long)_DIE_;
  }

#ifdef WANT_LD_SO_GDB_SUPPORT
  _r_debug.r_version=1;
  _r_debug.r_map=_dl_root_handle;
  _r_debug.r_brk=(void*)&_dl_debug_state;
  _r_debug.r_state=RT_CONSISTENT;
  _r_debug.r_ldbase=loadaddr;
  if (prog_dynamic) {
    for (i=0;prog_dynamic[i].d_tag;++i)
      if (prog_dynamic[i].d_tag==DT_DEBUG) {
	prog_dynamic[i].d_un.d_ptr=(Elf_Addr)&_r_debug;
#ifdef DEBUG
	pf(__FUNCTION__); pf(": set DT_DEBUG @ "); ph(prog_dynamic[i].d_un.d_val); pf("\n");
#endif
      }
  }
  _dl_debug_state();
#endif

  /* now start the program */
#ifdef DEBUG
  pf(__FUNCTION__); pf(": now jump to program entrypoint\n");
#endif
  return prog_entry;
}

#endif
