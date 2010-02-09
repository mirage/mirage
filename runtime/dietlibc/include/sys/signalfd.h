#ifndef _SYS_SIGNALFD_H
#define _SYS_SIGNALFD_H

#include <inttypes.h>

struct signalfd_siginfo { 
  uint32_t ssi_signo;
  int32_t ssi_errno;
  int32_t ssi_code;
  uint32_t ssi_pid;
  uint32_t ssi_uid;
  int32_t ssi_fd;
  uint32_t ssi_tid;
  uint32_t ssi_band;
  uint32_t ssi_overrun;
  uint32_t ssi_trapno;
  int32_t ssi_status;
  int32_t ssi_int;
  uint64_t ssi_ptr;
  uint64_t ssi_utime;
  uint64_t ssi_stime;
  uint64_t ssi_addr;
  uint8_t __pad[48];
};

__BEGIN_DECLS

extern int signalfd (int __fd, const sigset_t *__mask, int __flags)
  __nonnull ((2)) __THROW;

__END_DECLS

#endif
