/** Linux system call numbers for the ARM processor.
 * Written by Shaun Jackman <sjackman@gmail.com>
 * Copyright 2006 Pathway Connectivity
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#ifndef _LIBGLOSS_ARM_LINUX_UNISTD_H
#define _LIBGLOSS_ARM_LINUX_UNISTD_H

#if __thumb__
# define SYS_BASE 0
#else
# define SYS_BASE 0x900000
#endif

#define SYS_restart_syscall        (SYS_BASE+  0)
#define SYS_exit                   (SYS_BASE+  1)
#define SYS_fork                   (SYS_BASE+  2)
#define SYS_read                   (SYS_BASE+  3)
#define SYS_write                  (SYS_BASE+  4)
#define SYS_open                   (SYS_BASE+  5)
#define SYS_close                  (SYS_BASE+  6)
/*      SYS_waitpid                was         7 */
#define SYS_creat                  (SYS_BASE+  8)
#define SYS_link                   (SYS_BASE+  9)
#define SYS_unlink                 (SYS_BASE+ 10)
#define SYS_execve                 (SYS_BASE+ 11)
#define SYS_chdir                  (SYS_BASE+ 12)
#define SYS_time                   (SYS_BASE+ 13)
#define SYS_mknod                  (SYS_BASE+ 14)
#define SYS_chmod                  (SYS_BASE+ 15)
#define SYS_lchown                 (SYS_BASE+ 16)
/*      SYS_break                  was        17 */
/*      SYS_stat                   was        18 */
#define SYS_lseek                  (SYS_BASE+ 19)
#define SYS_getpid                 (SYS_BASE+ 20)
#define SYS_mount                  (SYS_BASE+ 21)
#define SYS_umount                 (SYS_BASE+ 22)
#define SYS_setuid                 (SYS_BASE+ 23)
#define SYS_getuid                 (SYS_BASE+ 24)
#define SYS_stime                  (SYS_BASE+ 25)
#define SYS_ptrace                 (SYS_BASE+ 26)
#define SYS_alarm                  (SYS_BASE+ 27)
/*      SYS_fstat                  was        28 */
#define SYS_pause                  (SYS_BASE+ 29)
#define SYS_utime                  (SYS_BASE+ 30)
/*      SYS_stty                   was        31 */
/*      SYS_gtty                   was        32 */
#define SYS_access                 (SYS_BASE+ 33)
#define SYS_nice                   (SYS_BASE+ 34)
/*      SYS_ftime                  was        35 */
#define SYS_sync                   (SYS_BASE+ 36)
#define SYS_kill                   (SYS_BASE+ 37)
#define SYS_rename                 (SYS_BASE+ 38)
#define SYS_mkdir                  (SYS_BASE+ 39)
#define SYS_rmdir                  (SYS_BASE+ 40)
#define SYS_dup                    (SYS_BASE+ 41)
#define SYS_pipe                   (SYS_BASE+ 42)
#define SYS_times                  (SYS_BASE+ 43)
/*      SYS_prof                   was        44 */
#define SYS_brk                    (SYS_BASE+ 45)
#define SYS_setgid                 (SYS_BASE+ 46)
#define SYS_getgid                 (SYS_BASE+ 47)
/*      SYS_signal                 was        48 */
#define SYS_geteuid                (SYS_BASE+ 49)
#define SYS_getegid                (SYS_BASE+ 50)
#define SYS_acct                   (SYS_BASE+ 51)
#define SYS_umount2                (SYS_BASE+ 52)
/*      SYS_lock                   was        53 */
#define SYS_ioctl                  (SYS_BASE+ 54)
#define SYS_fcntl                  (SYS_BASE+ 55)
/*      SYS_mpx                    was        56 */
#define SYS_setpgid                (SYS_BASE+ 57)
/*      SYS_ulimit                 was        58 */
/*      SYS_olduname               was        59 */
#define SYS_umask                  (SYS_BASE+ 60)
#define SYS_chroot                 (SYS_BASE+ 61)
#define SYS_ustat                  (SYS_BASE+ 62)
#define SYS_dup2                   (SYS_BASE+ 63)
#define SYS_getppid                (SYS_BASE+ 64)
#define SYS_getpgrp                (SYS_BASE+ 65)
#define SYS_setsid                 (SYS_BASE+ 66)
#define SYS_sigaction              (SYS_BASE+ 67)
/*      SYS_sgetmask               was        68 */
/*      SYS_ssetmask               was        69 */
#define SYS_setreuid               (SYS_BASE+ 70)
#define SYS_setregid               (SYS_BASE+ 71)
#define SYS_sigsuspend             (SYS_BASE+ 72)
#define SYS_sigpending             (SYS_BASE+ 73)
#define SYS_sethostname            (SYS_BASE+ 74)
#define SYS_setrlimit              (SYS_BASE+ 75)
#define SYS_getrlimit              (SYS_BASE+ 76)
#define SYS_getrusage              (SYS_BASE+ 77)
#define SYS_gettimeofday           (SYS_BASE+ 78)
#define SYS_settimeofday           (SYS_BASE+ 79)
#define SYS_getgroups              (SYS_BASE+ 80)
#define SYS_setgroups              (SYS_BASE+ 81)
#define SYS_select                 (SYS_BASE+ 82)
#define SYS_symlink                (SYS_BASE+ 83)
/*      SYS_lstat                  was        84 */
#define SYS_readlink               (SYS_BASE+ 85)
#define SYS_uselib                 (SYS_BASE+ 86)
#define SYS_swapon                 (SYS_BASE+ 87)
#define SYS_reboot                 (SYS_BASE+ 88)
#define SYS_readdir                (SYS_BASE+ 89)
#define SYS_mmap                   (SYS_BASE+ 90)
#define SYS_munmap                 (SYS_BASE+ 91)
#define SYS_truncate               (SYS_BASE+ 92)
#define SYS_ftruncate              (SYS_BASE+ 93)
#define SYS_fchmod                 (SYS_BASE+ 94)
#define SYS_fchown                 (SYS_BASE+ 95)
#define SYS_getpriority            (SYS_BASE+ 96)
#define SYS_setpriority            (SYS_BASE+ 97)
/*      SYS_profil                 was        98 */
#define SYS_statfs                 (SYS_BASE+ 99)
#define SYS_fstatfs                (SYS_BASE+100)
/*      SYS_ioperm                 was       101 */
#define SYS_socketcall             (SYS_BASE+102)
#define SYS_syslog                 (SYS_BASE+103)
#define SYS_setitimer              (SYS_BASE+104)
#define SYS_getitimer              (SYS_BASE+105)
#define SYS_stat                   (SYS_BASE+106)
#define SYS_lstat                  (SYS_BASE+107)
#define SYS_fstat                  (SYS_BASE+108)
/*      SYS_uname                  was       109 */
/*      SYS_iopl                   was       110 */
#define SYS_vhangup                (SYS_BASE+111)
/*      SYS_idle                   was       112 */
#define SYS_syscall                (SYS_BASE+113)
#define SYS_wait4                  (SYS_BASE+114)
#define SYS_swapoff                (SYS_BASE+115)
#define SYS_sysinfo                (SYS_BASE+116)
#define SYS_ipc                    (SYS_BASE+117)
#define SYS_fsync                  (SYS_BASE+118)
#define SYS_sigreturn              (SYS_BASE+119)
#define SYS_clone                  (SYS_BASE+120)
#define SYS_setdomainname          (SYS_BASE+121)
#define SYS_uname                  (SYS_BASE+122)
/*      SYS_modify_ldt             was       123 */
#define SYS_adjtimex               (SYS_BASE+124)
#define SYS_mprotect               (SYS_BASE+125)
#define SYS_sigprocmask            (SYS_BASE+126)
/*      SYS_create_module          was       127 */
#define SYS_init_module            (SYS_BASE+128)
#define SYS_delete_module          (SYS_BASE+129)
/*      SYS_get_kernel_syms        was       130 */
#define SYS_quotactl               (SYS_BASE+131)
#define SYS_getpgid                (SYS_BASE+132)
#define SYS_fchdir                 (SYS_BASE+133)
#define SYS_bdflush                (SYS_BASE+134)
#define SYS_sysfs                  (SYS_BASE+135)
#define SYS_personality            (SYS_BASE+136)
/*      SYS_afs_syscall            was       137 */
#define SYS_setfsuid               (SYS_BASE+138)
#define SYS_setfsgid               (SYS_BASE+139)
#define SYS__llseek                (SYS_BASE+140)
#define SYS_getdents               (SYS_BASE+141)
#define SYS__newselect             (SYS_BASE+142)
#define SYS_flock                  (SYS_BASE+143)
#define SYS_msync                  (SYS_BASE+144)
#define SYS_readv                  (SYS_BASE+145)
#define SYS_writev                 (SYS_BASE+146)
#define SYS_getsid                 (SYS_BASE+147)
#define SYS_fdatasync              (SYS_BASE+148)
#define SYS__sysctl                (SYS_BASE+149)
#define SYS_mlock                  (SYS_BASE+150)
#define SYS_munlock                (SYS_BASE+151)
#define SYS_mlockall               (SYS_BASE+152)
#define SYS_munlockall             (SYS_BASE+153)
#define SYS_sched_setparam         (SYS_BASE+154)
#define SYS_sched_getparam         (SYS_BASE+155)
#define SYS_sched_setscheduler     (SYS_BASE+156)
#define SYS_sched_getscheduler     (SYS_BASE+157)
#define SYS_sched_yield            (SYS_BASE+158)
#define SYS_sched_get_priority_max (SYS_BASE+159)
#define SYS_sched_get_priority_min (SYS_BASE+160)
#define SYS_sched_rr_get_interval  (SYS_BASE+161)
#define SYS_nanosleep              (SYS_BASE+162)
#define SYS_mremap                 (SYS_BASE+163)
#define SYS_setresuid              (SYS_BASE+164)
#define SYS_getresuid              (SYS_BASE+165)
/*      SYS_vm86                   was       166 */
/*      SYS_query_module           was       167 */
#define SYS_poll                   (SYS_BASE+168)
#define SYS_nfsservctl             (SYS_BASE+169)
#define SYS_setresgid              (SYS_BASE+170)
#define SYS_getresgid              (SYS_BASE+171)
#define SYS_prctl                  (SYS_BASE+172)
#define SYS_rt_sigreturn           (SYS_BASE+173)
#define SYS_rt_sigaction           (SYS_BASE+174)
#define SYS_rt_sigprocmask         (SYS_BASE+175)
#define SYS_rt_sigpending          (SYS_BASE+176)
#define SYS_rt_sigtimedwait        (SYS_BASE+177)
#define SYS_rt_sigqueueinfo        (SYS_BASE+178)
#define SYS_rt_sigsuspend          (SYS_BASE+179)
#define SYS_pread64                (SYS_BASE+180)
#define SYS_pwrite64               (SYS_BASE+181)
#define SYS_chown                  (SYS_BASE+182)
#define SYS_getcwd                 (SYS_BASE+183)
#define SYS_capget                 (SYS_BASE+184)
#define SYS_capset                 (SYS_BASE+185)
#define SYS_sigaltstack            (SYS_BASE+186)
#define SYS_sendfile               (SYS_BASE+187)
/*                                 reserved  188 */
/*                                 reserved  189 */
#define SYS_vfork                  (SYS_BASE+190)
#define SYS_ugetrlimit             (SYS_BASE+191)
#define SYS_mmap2                  (SYS_BASE+192)
#define SYS_truncate64             (SYS_BASE+193)
#define SYS_ftruncate64            (SYS_BASE+194)
#define SYS_stat64                 (SYS_BASE+195)
#define SYS_lstat64                (SYS_BASE+196)
#define SYS_fstat64                (SYS_BASE+197)
#define SYS_lchown32               (SYS_BASE+198)
#define SYS_getuid32               (SYS_BASE+199)
#define SYS_getgid32               (SYS_BASE+200)
#define SYS_geteuid32              (SYS_BASE+201)
#define SYS_getegid32              (SYS_BASE+202)
#define SYS_setreuid32             (SYS_BASE+203)
#define SYS_setregid32             (SYS_BASE+204)
#define SYS_getgroups32            (SYS_BASE+205)
#define SYS_setgroups32            (SYS_BASE+206)
#define SYS_fchown32               (SYS_BASE+207)
#define SYS_setresuid32            (SYS_BASE+208)
#define SYS_getresuid32            (SYS_BASE+209)
#define SYS_setresgid32            (SYS_BASE+210)
#define SYS_getresgid32            (SYS_BASE+211)
#define SYS_chown32                (SYS_BASE+212)
#define SYS_setuid32               (SYS_BASE+213)
#define SYS_setgid32               (SYS_BASE+214)
#define SYS_setfsuid32             (SYS_BASE+215)
#define SYS_setfsgid32             (SYS_BASE+216)
#define SYS_getdents64             (SYS_BASE+217)
#define SYS_pivot_root             (SYS_BASE+218)
#define SYS_mincore                (SYS_BASE+219)
#define SYS_madvise                (SYS_BASE+220)
#define SYS_fcntl64                (SYS_BASE+221)
/*      SYS_tux                    reserved  222 */
/*                                 unused    223 */
#define SYS_gettid                 (SYS_BASE+224)
#define SYS_readahead              (SYS_BASE+225)
#define SYS_setxattr               (SYS_BASE+226)
#define SYS_lsetxattr              (SYS_BASE+227)
#define SYS_fsetxattr              (SYS_BASE+228)
#define SYS_getxattr               (SYS_BASE+229)
#define SYS_lgetxattr              (SYS_BASE+230)
#define SYS_fgetxattr              (SYS_BASE+231)
#define SYS_listxattr              (SYS_BASE+232)
#define SYS_llistxattr             (SYS_BASE+233)
#define SYS_flistxattr             (SYS_BASE+234)
#define SYS_removexattr            (SYS_BASE+235)
#define SYS_lremovexattr           (SYS_BASE+236)
#define SYS_fremovexattr           (SYS_BASE+237)
#define SYS_tkill                  (SYS_BASE+238)
#define SYS_sendfile64             (SYS_BASE+239)
#define SYS_futex                  (SYS_BASE+240)
#define SYS_sched_setaffinity      (SYS_BASE+241)
#define SYS_sched_getaffinity      (SYS_BASE+242)
#define SYS_io_setup               (SYS_BASE+243)
#define SYS_io_destroy             (SYS_BASE+244)
#define SYS_io_getevents           (SYS_BASE+245)
#define SYS_io_submit              (SYS_BASE+246)
#define SYS_io_cancel              (SYS_BASE+247)
#define SYS_exit_group             (SYS_BASE+248)
#define SYS_lookup_dcookie         (SYS_BASE+249)
#define SYS_epoll_create           (SYS_BASE+250)
#define SYS_epoll_ctl              (SYS_BASE+251)
#define SYS_epoll_wait             (SYS_BASE+252)
#define SYS_remap_file_pages       (SYS_BASE+253)
/*      SYS_set_thread_area        reserved  254 */
/*      SYS_get_thread_area        reserved  255 */
#define SYS_set_tid_address        (SYS_BASE+256)
#define SYS_timer_create           (SYS_BASE+257)
#define SYS_timer_settime          (SYS_BASE+258)
#define SYS_timer_gettime          (SYS_BASE+259)
#define SYS_timer_getoverrun       (SYS_BASE+260)
#define SYS_timer_delete           (SYS_BASE+261)
#define SYS_clock_settime          (SYS_BASE+262)
#define SYS_clock_gettime          (SYS_BASE+263)
#define SYS_clock_getres           (SYS_BASE+264)
#define SYS_clock_nanosleep        (SYS_BASE+265)
#define SYS_statfs64               (SYS_BASE+266)
#define SYS_fstatfs64              (SYS_BASE+267)
#define SYS_tgkill                 (SYS_BASE+268)
#define SYS_utimes                 (SYS_BASE+269)
#define SYS_arm_fadvise64_64       (SYS_BASE+270)
#define SYS_pciconfig_iobase       (SYS_BASE+271)
#define SYS_pciconfig_read         (SYS_BASE+272)
#define SYS_pciconfig_write        (SYS_BASE+273)
#define SYS_mq_open                (SYS_BASE+274)
#define SYS_mq_unlink              (SYS_BASE+275)
#define SYS_mq_timedsend           (SYS_BASE+276)
#define SYS_mq_timedreceive        (SYS_BASE+277)
#define SYS_mq_notify              (SYS_BASE+278)
#define SYS_mq_getsetattr          (SYS_BASE+279)
#define SYS_waitid                 (SYS_BASE+280)

#define SYS_SOCKET      1
#define SYS_BIND        2
#define SYS_CONNECT     3
#define SYS_LISTEN      4
#define SYS_ACCEPT      5
#define SYS_GETSOCKNAME 6
#define SYS_GETPEERNAME 7
#define SYS_SOCKETPAIR  8
#define SYS_SEND        9
#define SYS_RECV        10
#define SYS_SENDTO      11
#define SYS_RECVFROM    12
#define SYS_SHUTDOWN    13
#define SYS_SETSOCKOPT  14
#define SYS_GETSOCKOPT  15
#define SYS_SENDMSG     16
#define SYS_RECVMSG     17

#endif /* _LIBGLOSS_ARM_LINUX_UNISTD_H */
