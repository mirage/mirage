#ifndef _SYSCALL_H_
#define _SYSCALL_H_

/*
 * This file defines the system calls for SPARC.
 *
 * WARNING: This file can be included by assembler files.
 */

#define	SYS_exit	1
#define	SYS_fork	2
#define	SYS_read	3
#define	SYS_write	4
#define	SYS_open	5
#define	SYS_close	6
#define	SYS_wait4	7
#define	SYS_creat	8
#define	SYS_link	9
#define	SYS_unlink	10
#define	SYS_execv	11
#define	SYS_chdir	12
#ifdef __svr4__
#define SYS_time	13	/* old time in sunos4 */
#endif
#define	SYS_mknod	14
#define	SYS_chmod	15
#define	SYS_chown	16
#define SYS_brk		17
#ifdef __svr4__
#define SYS_stat	18	/* old stat in sunos4 */
#endif
#define	SYS_lseek	19
#define	SYS_getpid	20
#ifdef __svr4__
#define SYS_mount	21	/* old mount in sunos4 */
#define SYS_umount	22	/* old umount in sunos4 */
#define SYS_setuid	23	/* old setuid in sunos4 */
#endif
#define	SYS_getuid	24
#ifdef __svr4__
#define SYS_stime	25	/* old stime in sunos4 */
#endif
#define	SYS_ptrace	26
#ifdef __svr4__
#define SYS_alarm	27	/* old alarm in sunos4 */
#define SYS_fstat	28	/* old fstat in sunos4 */
#define SYS_pause	29	/* old pause in sunos4 */
#define SYS_utime	30	/* old utime in sunos4 */
#define SYS_stty	31	/* old stty in sunos4 */
#define SYS_gtty	32	/* old gtty in sunos4 */
#endif
#define	SYS_access	33
#ifdef __svr4__
#define SYS_nice	34	/* old nice in sunos4 */
#define SYS_statfs	35	/* old ftime in sunos4 */
#endif
#define	SYS_sync	36
#define	SYS_kill	37
#ifdef __svr4__
#define	SYS_fstatfs	38
#define	SYS_pgrpsys	39	/* old setpgrp in sunos4 */
#define	SYS_xenix	40
#else
#define	SYS_stat	38
#define	SYS_lstat	40
#endif
#define	SYS_dup		41
#define	SYS_pipe	42
#define SYS_times	43	/* times is obsolete in sunos4, used anyway */
#define	SYS_profil	44
#ifdef __svr4__
#define SYS_plock	45	/* unused in sunos4 */
#define SYS_setgid	46	/* old setgid in sunos4 */
#endif
#define	SYS_getgid	47
#ifdef __svr4__
#define SYS_signal	48	/* old sigsys in sunos4 */
#define SYS_msgsys	49	/* unused in sunos4 */
#define SYS_sun		50	/* unused in sunos4 */
#endif
#define	SYS_acct	51
#ifdef __svr4__
#define SYS_shmsys	52	/* old phys in sunos4 */
#define	SYS_semsys	53
#else
#define	SYS_mctl	53
#endif
#define	SYS_ioctl	54
#ifdef __svr4__
#define	SYS_uadmin	55
#else
#define	SYS_reboot	55
#endif
				/* 56 is old: mpxchan (reserved in sunos5) */
#ifdef __svr4__
#define	SYS_utssys	57
#define	SYS_fsync	58
#else
#define	SYS_symlink	57
#define	SYS_readlink	58
#endif
#define	SYS_execve	59
#define	SYS_umask	60
#define	SYS_chroot	61
#ifdef __svr4__
#define	SYS_fcntl	62
#define SYS_ulimit	63	/* unused in sunos4 */
				/* 64-77 unused/reserved in sunos5 */
#else
#define	SYS_fstat	62
#define	SYS_getpagesize 64
#define	SYS_msync	65
				/* 66 is old: vfork */
				/* 67 is old: vread */
				/* 68 is old: vwrite */
#define	SYS_sbrk	69
#define	SYS_sstk	70
#define	SYS_mmap	71
#define	SYS_vadvise	72
#define	SYS_munmap	73
#define	SYS_mprotect	74
#define	SYS_madvise	75
#define	SYS_vhangup	76
				/* 77 is old: vlimit */
#endif

#ifdef __svr4__
#define	SYS_rfsys	78
#define	SYS_rmdir	79
#define	SYS_mkdir	80
#define	SYS_getdents	81
				/* 82 not used, was libattach */
				/* 83 not used, was libdetach */
#define	SYS_sysfs	84
#define	SYS_getmsg	85
#define	SYS_putmsg	86
#define	SYS_poll	87
#define	SYS_lstat	88
#define	SYS_symlink	89
#define	SYS_readlink	90
#define	SYS_setgroups	91
#define	SYS_getgroups	92
#define	SYS_fchmod	93
#define	SYS_fchown	94
#define	SYS_sigprocmask	95
#define	SYS_sigsuspend	96
#define	SYS_sigaltstack	97
#define	SYS_sigaction	98
#define	SYS_sigpending	99
#define	SYS_context	100
#define	SYS_evsys	101
#define	SYS_evtrapret	102
#define	SYS_statvfs	103
#define	SYS_fstatvfs	104
				/* 105 reserved */
#define	SYS_nfssys	106
#define	SYS_waitsys	107
#define	SYS_sigsendsys	108
#define	SYS_hrtsys	109
#define	SYS_acancel	110
#define	SYS_async	111
#define	SYS_priocntlsys	112
#define	SYS_pathconf	113
#define	SYS_mincore	114
#define	SYS_mmap	115
#define	SYS_mprotect	116
#define	SYS_munmap	117
#define	SYS_fpathconf	118
#define	SYS_vfork	119
#define	SYS_fchdir	120
#define	SYS_readv	121
#define	SYS_writev	122
#define	SYS_xstat	123
#define	SYS_lxstat	124
#define	SYS_fxstat	125
#define	SYS_xmknod	126
#define	SYS_clocal	127
#define	SYS_setrlimit	128
#define	SYS_getrlimit	129
#define	SYS_lchown	130
#define	SYS_memcntl	131
#define	SYS_getpmsg	132
#define	SYS_putpmsg	133
#define	SYS_rename	134
#define	SYS_uname	135
#define	SYS_setegid	136
#define	SYS_sysconfig	137
#define	SYS_adjtime	138
#define	SYS_systeminfo	139
#define	SYS_seteuid	141
#define	SYS_vtrace	142
#define	SYS_fork1	143
#define	SYS_sigwait	144
#define	SYS_lwp_info	145
#define	SYS_yield	146
#define	SYS_lwp_sema_p	147
#define	SYS_lwp_sema_v	148
#define	SYS_modctl	152
#define	SYS_fchroot	153
#define	SYS_utimes	154
#define	SYS_vhangup	155
#define	SYS_gettimeofday	156
#define	SYS_getitimer		157
#define	SYS_setitimer		158
#define	SYS_lwp_create		159
#define	SYS_lwp_exit		160
#define	SYS_lwp_suspend		161
#define	SYS_lwp_continue	162
#define	SYS_lwp_kill		163
#define	SYS_lwp_self		164
#define	SYS_lwp_setprivate	165
#define	SYS_lwp_getprivate	166
#define	SYS_lwp_wait		167
#define	SYS_lwp_mutex_unlock	168
#define	SYS_lwp_mutex_lock	169
#define	SYS_lwp_cond_wait	170
#define	SYS_lwp_cond_signal	171
#define	SYS_lwp_cond_broadcast	172
#define	SYS_pread		173
#define	SYS_pwrite		174
#define	SYS_llseek		175
#define	SYS_inst_sync		176
#define	SYS_auditsys		186
#else
#define	SYS_mincore	78
#define	SYS_getgroups	79
#define	SYS_setgroups	80
#define	SYS_getpgrp	81
#define	SYS_setpgrp	82
#define	SYS_setitimer	83
				/* 84 is old: wait & wait3 */
#define	SYS_swapon	85
#define	SYS_getitimer	86
#define	SYS_gethostname	87
#define	SYS_sethostname	88
#define	SYS_getdtablesize 89
#define	SYS_dup2	90
#define	SYS_getdopt	91
#define	SYS_fcntl	92
#define	SYS_select	93
#define	SYS_setdopt	94
#define	SYS_fsync	95
#define	SYS_setpriority	96
#define	SYS_socket	97
#define	SYS_connect	98
#define	SYS_accept	99
#define	SYS_getpriority	100
#define	SYS_send	101
#define	SYS_recv	102
				/* 103 was socketaddr */
#define	SYS_bind	104
#define	SYS_setsockopt	105
#define	SYS_listen	106
				/* 107 was vtimes */
#define	SYS_sigvec	108
#define	SYS_sigblock	109
#define	SYS_sigsetmask	110
#define	SYS_sigpause	111
#define	SYS_sigstack	112
#define	SYS_recvmsg	113
#define	SYS_sendmsg	114
#define	SYS_vtrace	115
#define	SYS_gettimeofday 116
#define	SYS_getrusage	117
#define	SYS_getsockopt	118
				/* 119 is old resuba */
#define	SYS_readv	120
#define	SYS_writev	121
#define	SYS_settimeofday 122
#define	SYS_fchown	123
#define	SYS_fchmod	124
#define	SYS_recvfrom	125
#define	SYS_setreuid	126
#define	SYS_setregid	127
#define	SYS_rename	128
#define	SYS_truncate	129
#define	SYS_ftruncate	130
#define	SYS_flock	131
				/* 132 is unused */
#define	SYS_sendto	133
#define	SYS_shutdown	134
#define	SYS_socketpair	135
#define	SYS_mkdir	136
#define	SYS_rmdir	137
#define	SYS_utimes	138
				/* 139 is unused */
#define	SYS_adjtime	140
#define	SYS_getpeername	141
#define	SYS_gethostid	142
				/* 143 is old: sethostid */
#define	SYS_getrlimit	144
#define	SYS_setrlimit	145
#define	SYS_killpg	146
				/* 147 is unused */
				/* 148 is old: setquota */
				/* 149 is old: quota */
#define	SYS_getsockname	150
#define	SYS_getmsg	151
#define	SYS_putmsg	152
#define	SYS_poll	153
				/* 154 is old: nfs_mount */
#define	SYS_nfssvc	155
#define	SYS_getdirentries 156
#define	SYS_statfs	157
#define	SYS_fstatfs	158
#define	SYS_unmount	159
#define	SYS_async_daemon 160
#define	SYS_getfh	161
#define	SYS_getdomainname 162
#define	SYS_setdomainname 163
				/* 164 is old: pcfs_mount */
#define	SYS_quotactl	165
#define	SYS_exportfs	166
#define	SYS_mount	167
#define	SYS_ustat	168
#define	SYS_semsys	169
#define	SYS_msgsys	170
#define	SYS_shmsys	171
#define	SYS_auditsys	172
#define	SYS_rfssys	173
#define	SYS_getdents	174
#define	SYS_setsid	175
#define	SYS_fchdir	176
#define	SYS_fchroot	177
#define	SYS_vpixsys	178

#define	SYS_aioread	179
#define	SYS_aiowrite	180
#define	SYS_aiowait	181
#define	SYS_aiocancel	182

#define	SYS_sigpending	183
				/* 184 is available */
#define	SYS_setpgid	185
#define	SYS_pathconf	186
#define	SYS_fpathconf	187
#define	SYS_sysconf	188

#define	SYS_uname	189

#endif /* ! __svr4__ */

#endif /* _SYSCALL_H_ */



