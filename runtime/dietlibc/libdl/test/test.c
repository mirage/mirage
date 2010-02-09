#include <dlfcn.h>

int main(int argc, char **argv)
{
  void *Hlib;

//  if (Hlib=dlopen("libtest.so", RTLD_LAZY)) {
  if (Hlib=dlopen("libtest.so", RTLD_NOW)) {
    void (*t)(void) = dlsym(Hlib,"test");
    if (t) {
      printf("test @ %08lx\n",(long)t);
      t();
    }
    dlclose(Hlib);
  }
  else {
    printf("%s\n",dlerror());
  }
  return 0;
}
