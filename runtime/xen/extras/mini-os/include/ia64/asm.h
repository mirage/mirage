/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com
 */

#if !defined(_ASM_H_)
#define _ASM_H_

#define	ENTRY(_name_)				\
	.global	_name_;				\
	.align	16;				\
	.proc	_name_;				\
_name_:;					\


#define	END(_name_)						\
	.endp	_name_

#endif /* !defined(_ASM_H_) */
