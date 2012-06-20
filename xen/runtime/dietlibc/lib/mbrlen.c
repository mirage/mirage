#include <wchar.h>
#include <errno.h>

static mbstate_t internal;

size_t mbrlen(const char *s, size_t n, mbstate_t *ps) {
  static mbstate_t internal;
  return mbrtowc (NULL, s, n, ps ?: &internal);
}
