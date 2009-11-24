/* Environment variable to be removed for SUID programs.  The names are
   all stuffed in a single string which means they have to be terminated
   with a '\0' explicitly.  */
#define UNSECURE_ENVVARS \
  "LD_PRELOAD\0"							      \
  "LD_LIBRARY_PATH\0"							      \
  "LD_ORIGIN_PATH\0"							      \
  "LD_DEBUG_OUTPUT\0"							      \
  "LD_PROFILE\0"							      \
  "GCONV_PATH\0"							      \
  "HOSTALIASES\0"							      \
  "LOCALDOMAIN\0"							      \
  "LOCPATH\0"								      \
  "MALLOC_TRACE\0"							      \
  "NLSPATH\0"								      \
  "RESOLV_HOST_CONF\0"							      \
  "RES_OPTIONS\0"							      \
  "TMPDIR\0"								      \
  "TZDIR\0"
