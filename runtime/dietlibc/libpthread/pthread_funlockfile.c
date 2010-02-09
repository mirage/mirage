#include "dietstdio.h"

void funlockfile(FILE* f) {
  pthread_mutex_unlock(&f->m);
}
