#include "dietstdio.h"

int ftrylockfile(FILE* f) {
  return pthread_mutex_trylock(&f->m);
}
