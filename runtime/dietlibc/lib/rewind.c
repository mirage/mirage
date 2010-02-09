#include <dietstdio.h>
#include <unistd.h>

void rewind( FILE *stream) {
  fseek(stream, 0L, SEEK_SET);
}
