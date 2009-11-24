#ifndef ASM_H
#define ASM_H

#ifdef __STDC__
# define _C_LABEL(x)    _ ## x
#else
# define _C_LABEL(x)    _/**/x
#endif
#define _ASM_LABEL(x)   x

#define _ENTRY(name)	\
	.text; .align 4; .globl name; name:

#define ENTRY(name)	\
	_ENTRY(_C_LABEL(name))

#endif
