#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

int main(int argc,char* argv[]) {
  char salt[2];
  char charset[100];
  unsigned int l,i;
  int fd;
  salt[0]='a';
  salt[1]='b';
  assert(!strcmp(crypt("fnord",salt),"ab3MSJErI/bdM"));

  for (l=i=0; i<'z'-'a'; ++i) { charset[l]=i+'a'; ++l; }
  for (i=0; i<'Z'-'A'; ++i) { charset[l]=i+'A'; ++l; }
  for (i=0; i<'9'-'0'; ++i) { charset[l]=i+'0'; ++l; }
  charset[l]='.'; charset[l+1]='/'; i=l+2;
  fd=open("/dev/urandom",O_RDONLY);
  read(fd,&l,sizeof(l));
  salt[0]=charset[l%i];
  salt[1]=charset[(l/i)%i];
  close(fd);
  for (l=1; argv[l]; ++l) {
    printf("password %s with salt %c%c -> %s\n",argv[l],salt[0],salt[1],crypt(argv[l],salt));
    printf("md5password %s -> %s\n",argv[l],crypt(argv[l],"$1$"));
  }
}
