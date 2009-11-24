;
;
; File of stubs so that unix applications can link into a HIF monitor
;
; sac@cygnus.com

	.text

	.global	_sysalloc
_sysalloc:
	const	gr121,__sysalloc
	consth	gr121,__sysalloc
	jmpi	gr121

	.global	_sysfree
_sysfree:
	const	gr121,__sysfree
	consth	gr121,__sysfree
	jmpi	gr121


	.global	_cycles
_cycles:
	const	gr121,__cycles
	consth	gr121,__cycles
	jmpi	gr121

;	.global	_exit
;_exit:
;	const	gr121,__exit
;	consth	gr121,__exit
;	jmpi	gr121

	.global	_getpsiz
_getpsiz:
	const	gr121,__getpsiz
	consth	gr121,__getpsiz
	jmpi	gr121

	.global	_gettz
_gettz:
	const	gr121,__gettz
	consth	gr121,__gettz
	jmpi	gr121

	.global	_ioctl
_ioctl:
	const	gr121,__ioctl
	consth	gr121,__ioctl
	jmpi	gr121


	.global	_iowait
_iowait:
	const	gr121,__iowait
	consth	gr121,__iowait
	jmpi	gr121


;; syscalls used now -- 	.global	_open
;; syscalls used now -- _open:
;; syscalls used now -- 	const	gr121,__open
;; syscalls used now -- 	consth	gr121,__open
;; syscalls used now -- 	jmpi	gr121

	.global	_query
_query:
	const	gr121,__query
	consth	gr121,__query
	jmpi	gr121


	.global	_setim
_setim:
	const	gr121,__setim
	consth	gr121,__setim
	jmpi	gr121

	.global	_settrap
_settrap:
	const	gr121,__settrap
	consth	gr121,__settrap
	jmpi	gr121

	.global	_setvec
_setvec:
	const	gr121,__setvec
	consth	gr121,__setvec
	jmpi	gr121

	.global	_getargs
_getargs:
	const	gr121,__getargs
	consth	gr121,__getargs
	jmpi	gr121

;; syscalls used now -- 	.global	_unlink
;; syscalls used now -- _unlink:
;; syscalls used now -- 	const	gr121,__unlink
;; syscalls used now -- 	consth	gr121,__unlink
;; syscalls used now -- 	jmpi	gr121

	.global	_sigret
_sigret:
	const	gr121,__sigret
	consth	gr121,__sigret
	jmpi	gr121

	.global	_sigdfl
_sigdfl:
	const	gr121,__sigdfl
	consth	gr121,__sigdfl
	jmpi	gr121

	.global	_sigrep
_sigrep:
	const	gr121,__sigrep
	consth	gr121,__sigrep
	jmpi	gr121

	.global	_sigskp
_sigskp:
	const	gr121,__sigskp
	consth	gr121,__sigskp
	jmpi	gr121

	.global	_sendsig
_sendsig:
	const	gr121,__sendsig
	consth	gr121,__sendsig
	jmpi	gr121

	; fill this jmpi delay slot
	; the others are not done since they do not matter
	constn  lr0,-1
