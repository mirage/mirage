#include "asm.h"

ENTRY(_exit)
	lda	257,g13
	calls	g13

ENTRY(_sys_open)
	lda	230,g13
        calls	g13
	ret

ENTRY(_sys_read)
        lda	231,g13
	calls	g13
	ret

ENTRY(_sys_write)
	lda	232,g13
	calls	g13
	ret

ENTRY(_sys_lseek)
	lda	233,g13
	calls	g13
	ret

ENTRY(_sys_close)
	lda	234,g13
	calls	g13
	ret
