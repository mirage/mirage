#define HAVE_WEAK_SYMBOLS 1
#define HAVE_GNU_LD 1
#define HAVE_ELF 1
#define __ASSUME_REALTIME_SIGNALS 1
#define ASM_GLOBAL_DIRECTIVE .global

#define TEMP_FAILURE_RETRY(expression) \
  (__extension__                                                              \
    ({ long int __result;                                                     \
       do __result = (long int) (expression);                                 \
       while (__result == -1L && errno == EINTR);                             \
       __result; }))

