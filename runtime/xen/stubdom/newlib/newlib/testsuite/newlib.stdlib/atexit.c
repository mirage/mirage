#include <stdlib.h>
#include <stdio.h>

void a(void);
void b(void);
void c(int, void *);
static void newline(void);

void a (void)
{
  printf("a");
}

void b (void)
{
  printf("b");
}

void c (int code, void *k)
{
  char *x = (char *)k;
  printf("%d%c",code,x[0]);
}

static void newline (void)
{
  printf("\n");
}

int main()
{
  if (atexit(newline) != 0)
    abort();

  if (atexit(a) != 0)
    abort();

  if (atexit(b) != 0)
    abort();

  if (on_exit(c,(void *)"c") != 0)
    abort();

  if (atexit(a) != 0)
    abort();

  exit(0);
}
