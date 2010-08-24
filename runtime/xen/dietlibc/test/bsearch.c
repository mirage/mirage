#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>

int compint(const void *a, const void *b) {
  register const int* A=a;
  register const int* B=b;
  return *B-*A;
}

void die(const char* message) {
  write(2,message,strlen(message));
  exit(1);
}

int main() {
#define SIZE 1000
  int array[SIZE],array2[SIZE];
  int i,j;
  int *k;
  for (j=10; j<SIZE; ++j) {
    for (i=0; i<j; ++i) array[i]=rand();
    memcpy(array2,array,sizeof(array));
    qsort(array,j,sizeof(int),compint);
    for (i=0; i<j-1; ++i)
      if (array[i]<array[i+1])
	die("not sorted after qsort!\n");
    for (i=0; i<j; ++i) {
      printf("element %d: ",i);
      k=bsearch(array+i,array,j,sizeof(int),compint);
      if (!k) {
	k=bsearch(array+i,array,j,sizeof(int),compint);
	die("bsearch returned NULL\n");
      }
      if (k != array+i) die("bsearch found wrong element\n");
      printf("%d\n",k-array);
    }
  }
  return 0;
}
