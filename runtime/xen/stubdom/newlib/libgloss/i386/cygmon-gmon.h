#ifndef GMON_CYGMON_H
#define GMON_CYGMON_H

struct phdr 
{
  char    *lpc;
  char    *hpc;
  int     ncnt;
};


#define HISTFRACTION 2
#define HISTCOUNTER unsigned short
#define HASHFRACTION 1
#define ARCDENSITY 2
#define MINARCS 50

struct tostruct 
{
  char *selfpc;
  long count;
  unsigned short link;
};

struct rawarc 
{
    unsigned long       raw_frompc;
    unsigned long       raw_selfpc;
    long                raw_count;
};

#define ROUNDDOWN(x,y)  (((x)/(y))*(y))
#define ROUNDUP(x,y)    ((((x)+(y)-1)/(y))*(y))

#endif
