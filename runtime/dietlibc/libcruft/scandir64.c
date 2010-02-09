#include <stdlib.h>
#include <dirent.h>
#include <string.h>

int scandir64(const char *dir, struct dirent64 ***namelist,
	    int (*select)(const struct dirent64 *),
	    int (*compar)(const struct dirent64 **, const struct dirent64 **)) {
  DIR* d;
  struct dirent64 *D;
  int num=0;
  if (!(d=opendir(dir)))
    return -1;
  *namelist=0;
  while ((D=readdir64(d))) {
    if (select==0 ||  select(D)) {
      struct dirent64 **tmp;
      ++num;
/*      printf("realloc %p,%d -> ",*namelist,num*sizeof(struct dirent**)); */
      if (!(tmp=realloc(*namelist,num*sizeof(struct dirent64**))) ||
	  !(tmp[num-1]=malloc(sizeof(struct dirent64)))) {
	int i;
	for (i=0; i<num-1; ++i) free(tmp[i]);
	free(*namelist);
	closedir(d);
	return -1;
      }
      memccpy(tmp[num-1]->d_name,D->d_name,0,NAME_MAX);
      tmp[num-1]->d_off=D->d_off;
      tmp[num-1]->d_reclen=D->d_reclen;
      tmp[num-1]->d_type=D->d_type;
      *namelist=tmp;
/*      printf("%p; tmp[num-1(%d)]=%p\n",*namelist,num-1,tmp[num-1]); */
    }
  }
  closedir(d);
#if 0
  {
    int i;
    puts("pre-qsort:\n");
    for (i=0; i<num-1; ++i) {
      puts((*namelist)[i]->d_name);
    }
    puts("post-qsort:\n");
  }
#endif
//  qsort(&(*namelist)[0],num,sizeof(struct dirent*),(int (*)(const void*,const void*))(compar));
  if (compar)
    qsort(*namelist,num,sizeof(struct dirent64*),(int (*)(const void*,const void*))(compar));
  return num;
}
