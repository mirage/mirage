#include <stdlib.h>
#include <dlfcn.h>

#include <fcntl.h>

#include "_dl_int.h"

#define WANT_LD_SO_CONF_SEARCH

static const char *_dl_search_rpath=0;

#ifndef __DIET_LD_SO__
#include <unistd.h>
#include <string.h>
void _dl_set_rpath(const char *path) { _dl_search_rpath=path; }
const char* _dl_get_rpath() { return _dl_search_rpath; }
#define _dl_lib_memcpy memcpy
#endif

/* search a colon (semicolon) seperated path for the libraray "filename" */
static int _dl_search_path(char*buf,int len,const char*path,const int pathlen,const char*filename) {
  int fd,i=1,fl=_dl_lib_strlen(filename),ml=len-fl;
  const char*c,*pe=path+pathlen;

  if (path) {
    for (c=path;c<pe;c+=i) {
      int l=len-1;
      if ((*c==':')||(*c==';')) ++c;
      i=_dl_lib_strcspn(c,":;");
      if (i) {
	if (i>ml) continue;	/* if len(path-entry)+len(filename)+2 is greater than the buffer ? SKIP */
	_dl_lib_memcpy(buf,c,i);
	buf[i]='/';
	l-=++i;
      }
      _dl_lib_memcpy(buf+i,filename,fl);
      buf[i+fl]=0;
#ifdef DEBUG
//      pf(__func__": "); pf(buf); pf("\n");
#endif
#ifdef __DIET_LD_SO__
      if ((fd=_dl_sys_open(buf,O_RDONLY,0))>-1) return fd;
#else
      if ((fd=open(buf,O_RDONLY))!=-1) return fd;
#endif
    }
  }
  return -1;
}

/* parse the SMALL file "conf" for lib directories (aem... hang me if you can :) ) */
static int _dl_search_conf(char*buf,int len,const char*conf,const char*filename) {
  char ld_so_conf[1024];
  int i,l,fd;
#ifdef __DIET_LD_SO__
  if ((fd=_dl_sys_open(conf,O_RDONLY,0))>-1) {
    l=_dl_sys_read(fd,ld_so_conf,sizeof(ld_so_conf)-1);
#else
  if ((fd=open(conf,O_RDONLY))!=-1) {
    l=read(fd,ld_so_conf,sizeof(ld_so_conf)-1);
#endif
    ld_so_conf[sizeof(ld_so_conf)-1]=0;
#ifdef __DIET_LD_SO__
    _dl_sys_close(fd);
#else
    close(fd);
#endif
    if (l>0) {
      if (ld_so_conf[l-1]=='\n') ld_so_conf[--l]=0;
      for (i=0;i<l;i++) if (ld_so_conf[i]=='\n') ld_so_conf[i]=':';
      if ((fd=_dl_search_path(buf,len,ld_so_conf,l,filename))!=-1) return fd;
    }
  }
  return -1;
}

#ifdef __DIET_LD_SO__
static
#endif
int _dl_search(char*buf,int len,const char*filename) {
  int fd;

  /* 1. search the LD_RUN_PATH (from the executable) */
  if (_dl_search_rpath) {
    if ((fd=_dl_search_path(buf,len,_dl_search_rpath,_dl_lib_strlen(_dl_search_rpath),filename))!=-1) return fd;
  }

  /* 2. IF we have a "secure" enviroment THEN search LD_LIBRARY_PATH */
#ifdef __DIET_LD_SO__
  if ((at_uid==at_euid)&&(at_gid==at_egid)) {
#else
  if ((getuid()==geteuid())&&(getgid()==getegid())) {
#endif
    char *p=getenv("LD_LIBRARY_PATH");
    if (p)
      if ((fd=_dl_search_path(buf,len,p,_dl_lib_strlen(p),filename))!=-1) return fd;
  }

  /* 3. search all pathes in the the /etc/diet.ld.conf, a dietlibc extension :) */
  if ((fd=_dl_search_conf(buf,len,"/etc/diet.ld.conf",filename))!=-1) return fd;

#ifdef WANT_LD_SO_CONF_SEARCH
  /* 4. search all pathes in the the /etc/ld.so.conf / can't handle this ...=lib?? crap */
  if ((fd=_dl_search_conf(buf,len,"/etc/ld.so.conf",filename))!=-1) return fd;
#endif

  /* default path search */
  {
    const char*def_path="/usr/lib:/lib";
    return _dl_search_path(buf,len,def_path,_dl_lib_strlen(def_path),filename);
  }
}
