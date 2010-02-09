#include <stdio.h>

int main() {
  FILE* f=fopen("testing","w");
  fputs("testing",f);
  return 0;
}
