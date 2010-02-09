#include <dietstdio.h>

int fflush(FILE *stream) {
  int tmp;
  if (stream) pthread_mutex_lock(&stream->m);
  tmp=fflush_unlocked(stream);
  if (stream) pthread_mutex_unlock(&stream->m);
  return tmp;
}
