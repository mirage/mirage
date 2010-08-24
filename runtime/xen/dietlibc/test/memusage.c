#include <stdio.h>

int main() {
  FILE* f=fopen("/proc/self/statm","r");
  int size,resident,shared;
  if (fscanf(f,"%d %d %d",&size,&resident,&shared)==3) {
    printf("%dK total size, %dK resident, %dK shared\n",
	   size*4,resident*4,shared*4);
  }
  return 0;
}
