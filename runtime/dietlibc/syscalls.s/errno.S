.section ".bss"
.align 8

.type errno,object
.weak errno
errno:
	.long 0
.size errno,.-errno
