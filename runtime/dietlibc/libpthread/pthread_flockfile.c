#include "dietstdio.h"

void flockfile(FILE* f) {
  pthread_mutex_lock(&f->m);
}
