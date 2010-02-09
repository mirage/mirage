#define _FILE_OFFSET_BITS 64
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <ftw.h>
#include <dirent.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>

#ifdef __dietlibc__
#include "dietdirent.h"
#endif

#ifndef O_DIRECTORY
#define O_DIRECTORY 0
#endif

#ifdef __NO_STAT64
int ftw64(const char*dir,int(*f)(const char*file,const struct stat* sb,int flag),int dpth) __THROW;
#endif

int ftw64(const char*dir,int(*f)(const char*file,const struct stat* sb,int flag),int dpth){
  char* cd;
  size_t cdl;
  DIR* d;
  struct dirent* de;
  struct stat sb;
  int r;
  unsigned int oldlen=0;
  char* filename = NULL;
  int previous=open(".",O_RDONLY|O_DIRECTORY);
#if !defined(__dietlibc__) && !defined(__MINGW32__)
  int thisdir;
#endif
  if (chdir(dir)) return -1;
  cd=alloca(PATH_MAX+1);
  if (!getcwd(cd,PATH_MAX) || !(d=opendir("."))) {
    close(previous);
    return -1;
  }
  cd[PATH_MAX]='\0';
  cdl=strlen(cd);
#if !defined(__dietlibc__) && !defined(__MINGW32__)
  if ((thisdir=open(".",O_RDONLY|O_DIRECTORY))==-1) {
    closedir(d); return -1;
  }
#endif
  while((de=readdir(d))){
    int flg;
    size_t nl;
    if(de->d_name[0]=='.'){if(!de->d_name[1])continue;if(de->d_name[1]=='.'&&!de->d_name[2])continue;}
    nl=strlen(de->d_name);
    if (nl+cdl+2>oldlen)
      filename=alloca(oldlen=nl+cdl+2);
    memmove(filename,cd,cdl);
    filename[cdl]='/';
    memmove(filename+cdl+1,de->d_name,nl+1);
    if(!lstat(de->d_name,&sb)){
      if(S_ISLNK(sb.st_mode))flg=FTW_SL;else if(S_ISDIR(sb.st_mode))flg=FTW_D;else flg=FTW_F;
    }else flg=FTW_NS;
    r=f(filename,&sb,flg);
    if(r){
err:
#if !defined(__dietlibc__) && !defined(__MINGW32__)
      close(thisdir);
#endif
      closedir(d);
      fchdir(previous);
      close(previous);
      return r;
    }
    if(flg==FTW_D&&dpth){
      r=ftw(filename,f,dpth-1);
#ifndef __dietlibc__
#ifdef __MINGW32__
      chdir("..");
#else
      fchdir(thisdir);
#endif
#else
      fchdir(d->fd);
#endif
      if (r) goto err;
    }
  }
  fchdir(previous);
  close(previous);
#if !defined(__dietlibc__) && !defined(__MINGW32__)
  close(thisdir);
#endif
  return closedir(d);
}
