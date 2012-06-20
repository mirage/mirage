#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <unistd.h>
#include <endian.h>
#include <stdlib.h>
#include <dirent.h>
#include <pwd.h>
#include <shadow.h>
#include <stdio.h>
#include <assert.h>
#include <sys/mount.h>
#include <time.h>
#include <sys/stat.h>
#include <stdio.h>
#include <arpa/inet.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <math.h>
#include <termios.h>
#include <netdb.h>
#include <sys/mman.h>
#include <ctype.h>
#include <mntent.h>
#include <regex.h>
#include <sys/types.h>
#include <sys/msg.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <signal.h>
#include <sys/io.h>
#include <getopt.h>
#include <arpa/nameser.h>
#include <resolv.h>
#include <fnmatch.h>
#include <stdarg.h>
#include <sys/wait.h>
#include <libgen.h>
#include <math.h>
#include <errno.h>
#include <syslog.h>
#include <sys/un.h>
#include <fcntl.h>
#include <iconv.h>
#include <features.h>
#include <sys/ioctl.h>
#include <pty.h>
#include <sys/statfs.h>
#include <mqueue.h>
#ifdef __dietlibc__
#include <md5.h>
#include <write12.h>
#endif

#if 0
static const char* Ident;
static int Option;
static int Facility;
static struct sockaddr_un sock;
static int fd=-1;

static void syslogconnect(void) {
  sock.sun_family=AF_UNIX;
  strcpy(sock.sun_path,"/dev/log");
  if ((fd=socket(AF_UNIX,SOCK_STREAM,0))==-1) return;
  if (connect(fd,(struct sockaddr*)&sock,sizeof(sock))==-1) {
    int save=errno;
    close(fd);
    fd=-1;
  }
  fcntl(fd,F_SETFL,FD_CLOEXEC);		/* doesn't work?  too bad */
}

void openlog(const char *ident, int option, int facility) {
  Ident=ident;
  Option=option;
  Facility=facility;
  syslogconnect();
}

void syslog(int priority, const char *format, ...) {
  /* write(fd,"<13>Jun 29 19:21:32 leitner: fnord",...) */
}

void closelog(void) {
}
#endif

void foo(int tmp,...) {
  long long l;
  va_list va;
  va_start(va,tmp);
  l=va_arg(va,long long);
  if (l!=-1) write(2,"kaputt\n",7);
}

int compint(const void *a, const void *b) {
  register const int* A=a;
  register const int* B=b;
  return *B-*A;
}

extern char* strcpy2(char*a,char*b);

#define rdtscl(low) \
     __asm__ __volatile__ ("rdtscp" : "=a" (low) : : "ecx","edx")

#define malloc(x) ({typeof(x) y=x; (y<0 || (size_t)(y)!=y ? 0 : malloc(y));})

int main(int argc,char *argv[]) {
#if 0
  char* a=malloc(-3);
  char* b=malloc(0xffffffffull+1);
  printf("%p %p\n",a,b);
#endif
  printf("%u\n",getpagesize());
#if 0
  struct stat s;
  time_t t=time(0);
  struct tm* T;
  stat("/tmp/nyt.html",&s);
  T=gmtime(&s.st_mtime);
#endif
#if 0
  static struct mq_attr x;
  mqd_t a=mq_open("fnord",O_WRONLY|O_CREAT,0600,&x);
  mqd_t b=mq_open("fnord",O_RDONLY);
#endif
#if 0
  struct statfs s;
  if (statfs("/tmp",&s)!=-1) {
    printf("%llu blocks, %llu free\n",(unsigned long long)s.f_blocks,(unsigned long long)s.f_bfree);
  }
#endif
#if 0
  char* c=strndupa("fnord",3);
  puts(c);
#endif
#if 0
  char buf[100];
  __write2("foo!\n");
  memset(buf,0,200);
#endif
#if 0
  printf("%+05d\n",500);
#endif
#if 0
  char* c;
  printf("%d\n",asprintf(&c,"foo %d",23));
  puts(c);
#endif
#if 0
  struct winsize ws;
  if (!ioctl(0, TIOCGWINSZ, &ws)) {
    printf("%dx%d\n",ws.ws_col,ws.ws_row);
  }
#endif
#if 0
  struct termios t;
  if (tcgetattr(1,&t)) { puts("tcgetattr failed!"); return 1; }
  printf("%d\n",cfgetospeed(&t));
#endif
#if 0
  printf("%p\n",malloc(0));
#endif
#if 0
  char* argv[]={"sh","-i",0};
  char buf[PATH_MAX+100];
  int i;
  for (i=0; i<PATH_MAX+20; ++i) buf[i]='a';
  memmove(buf,"PATH=/",6);
  strcpy(buf+i,"/bin:/bin");
  putenv(buf);
  execvp("sh",argv);
  printf("%d\n",islower('ü'));
#endif
#if 0
  char buf[101];
  __dtostr(-123456789.456,buf,100,6,2);
  puts(buf);
  return 0;
#endif
#if 0
  time_t t=1009921588;
  puts(asctime(localtime(&t)));
#endif
#if 0
  printf("%g\n",atof("30"));
#endif
#if 0
  char* buf[]={"FOO=FNORD","A=B","C=D","PATH=/usr/bin:/bin",0};
  environ=buf;
  putenv("FOO=BAR");
  putenv("FOO=BAZ");
  putenv("BLUB=DUH");
  system("printenv");
#endif
#if 0
  char buf[1024];
  time_t t1=time(0);
  struct tm* t=localtime(&t1);
  printf("%d %s\n",strftime(buf,sizeof buf,"%b %d %H:%M",t),buf);
#endif
#if 0
  tzset();
  printf("%d\n",daylight);
#endif
#if 0
  struct in_addr addr;
  inet_aton("10.0.0.100\t",&addr);
  printf("%s\n",inet_ntoa(addr));
#endif
#if 0
  printf("%u\n",getuid32());
#endif
#if 0
  FILE *f;
  int i;
  char addr6p[8][5];
  int plen, scope, dad_status, if_idx;
  char addr6[40], devname[20];
  if ((f = fopen("/proc/net/if_inet6", "r")) != NULL) {
    while ((i=fscanf(f, "%4s%4s%4s%4s%4s%4s%4s%4s %02x %02x %02x %02x %20s\n",
		addr6p[0], addr6p[1], addr6p[2], addr6p[3],
		addr6p[4], addr6p[5], addr6p[6], addr6p[7],
		&if_idx, &plen, &scope, &dad_status, devname)) != EOF) {
      printf("i=%d\n",i);
    }
  }
#endif
#if 0
  printf("%s\n",crypt("test","$1$"));
#endif
#if 0
  MD5_CTX x;
  unsigned char md5[16];
  MD5Init(&x);
  MD5Update(&x,"a",1);
  MD5Final(md5,&x);
  {
    int i;
    for (i=0; i<16; ++i) {
      printf("%02x",md5[i]);
    }
    putchar('\n');
  }
#endif
#if 0
  long a,b,c;
  char buf[20]="fnord";
  strcpy(buf,"Fnordhausen");
  strcpy2(buf,"Fnordhausen");
  rdtscl(a);
  strcpy(buf,"Fnordhausen");
  rdtscl(b);
  strcpy2(buf,"Fnordhausen");
  rdtscl(c);
  printf("C: %d ticks, asm: %d ticks\n",b-a,c-b);
#endif

/*  printf("%d\n",strcmp(buf,"fnord")); */
#if 0
  regex_t r;
//  printf("regcomp %d\n",regcomp(&r,"^(re([\\[0-9\\]+])*|aw):[ \t]*",REG_EXTENDED));
  printf("regcomp %d\n",regcomp(&r,"^([A-Za-z ]+>|[]>:|}-][]>:|}-]*)",REG_EXTENDED));
  printf("regexec %d\n",regexec(&r,"Marketing-Laufbahn hinterdir.",1,0,REG_NOSUB));
#endif
#if 0
  FILE *f=fopen("/home/leitner/Mail/outbox","r");
  char buf[1024];
  int i=0;
  if (f) {
    while (fgets(buf,1023,f)) {
      ++i;
      printf("%d %lu %s",i,ftell(f),buf);
    }
  }
#endif
#if 0
  char template[]="/tmp/duh/fnord-XXXXXX";
  printf("%d\n",mkdtemp(template));
#endif
#if 0
  char *inbuf="\xe2\x89\xa0";
//  char *inbuf="\xc2\xa9";
  char outbuf[100];
  char *obptr=&outbuf;
  size_t iblen=strlen(inbuf);
  size_t oblen=100;
  iconv_t i=iconv_open("utf-8","utf-8");
  iconv(i,&inbuf,&iblen,&obptr,&oblen);
  iconv_close(i);
  outbuf[100-oblen]=0;
  puts(outbuf);
#endif
#if 0
  printf("%c %c\n",tolower('C'),toupper('c'));
#endif
#if 0
  printf("foo\n");
#endif
#if 0
  char strport[10];
  int i;
  for (i=0; i<10; ++i) strport[i]=i+'0';
  snprintf( strport, sizeof(strport), "%d", 80 );
  puts(strport);
#endif
#if 0
  struct addrinfo *ai;
  struct addrinfo hints;
  char buf[16];
  memset(&hints,0,sizeof(hints));
#if 0
  hints.ai_family = AF_UNSPEC;
  hints.ai_flags = AI_PASSIVE;
  hints.ai_socktype = SOCK_STREAM;
#endif
  hints.ai_family=0;
  hints.ai_flags=0;
  hints.ai_socktype=1;
  hints.ai_protocol=0;
  hints.ai_addrlen=0;
  hints.ai_addr=0;
  hints.ai_canonname=0;
  hints.ai_next=0;
  printf("%d\n",getaddrinfo("news.fu-berlin.de","119",&hints,&ai));
  while (ai) {
    printf("found host %s, port %d, family %s, socktype %s\n",ai->ai_canonname,
	   ntohs(ai->ai_family==AF_INET6?((struct sockaddr_in6*)ai->ai_addr)->sin6_port:
				   ((struct sockaddr_in*)ai->ai_addr)->sin_port),
	   ai->ai_family==AF_INET6?"PF_INET6":"PF_INET",
	   ai->ai_socktype==SOCK_STREAM?"SOCK_STREAM":"SOCK_DGRAM");
    {
      char buf[100];
      inet_ntop(ai->ai_family,ai->ai_family==AF_INET6?
		(char*)&(((struct sockaddr_in6*)ai->ai_addr)->sin6_addr):
		(char*)&(((struct sockaddr_in*)ai->ai_addr)->sin_addr),buf,100);
      printf("  %s\n",buf);
    }
    ai=ai->ai_next;
  }
#endif
#if 0
  char buf[101];
  __dtostr(M_PI,buf,100,6);
#endif
#if 0
  printf("%d\n",strcasecmp("foo","FOO"));
#endif
#if 0
  printf("%.24s", "Sun Jan  2 08:29:13 1994\n");
#endif
#if 0
  printf("%.*s\n",13,"fnord");
#endif
#if 0
  double d=strtod(argv[1],0);
  printf("%g|\n",d);
#endif
#if 0
  char buf[100];
  printf("%d\n",__lltostr(buf,30,-1ll,10,0));
  puts(buf);
#endif
#if 0
  printf("%lld\n",-1ll);
#endif
#if 0
  char *str="e";
  setbuf(stdout,0);
  printf("foo\n");
  fputc(toupper(*str++),stdout);
  printf("bar\n");
#endif
#if 0
  fwrite("foobar",6,1,stdout);
#endif
#if 0
  char x[5];
  x[4]='x';
  fgets(x,4,stdin);
  puts(x);
  printf("%c\n",x[4]);
#endif
#if 0
  char* paths[]={"/usr/lib","/usr/","usr","/",".",".."};
  char* want[]={"/usr","/",".","/",".","."};
  int i;
  for (i=0; i<6; ++i) {
    printf("%s\t%s\t%s\n",paths[i],want[i],dirname(strdup(paths[i])));
  }
#endif
#if 0
  char* paths[]={"/usr/lib","/usr/","usr","/",".",".."};
  char* want[]={"lib","usr","usr","/",".",".."};
  int i;
  for (i=0; i<6; ++i) {
    printf("%s\t%s\t%s\n",paths[i],want[i],basename(strdup(paths[i])));
  }
#endif
#if 0
  int i;
  for (i=0; i<255; ++i) {
    int a=isalpha(i);
    int b=(i>='a' && i<='z') || (i>='A' && i<='Z');
    if (a!=b) printf("%d: %d %d\n",i,a,b);
  }
#endif
#if 0
  char* name;
  int ptyfd,ttyfd;
  int i=openpty(&ptyfd,&ttyfd,0,0,0);
  if (i<0) perror("openpty");
  printf("%d %d\n",ptyfd,ttyfd);
  printf("%s %s\n",ttyname(ptyfd),ttyname(ttyfd));
#endif
#if 0
  printf("0x%8.7lx\n",0xfefe);
#endif
#if 0
  puts(ttyname(0));
#endif
#if 0
  char buf[1024];
  struct hostent* r;
  int i=0;
  r=gethostbyname("cyberelks.net");
again:
  if (!r) {
    printf("dns error: %s\n",hstrerror(h_errno));
  }
  {
/*  while (r=gethostent_r(buf,1024)) { */
    if (r && r->h_name) {
      int i;
      printf("name \"%s\"; ", r->h_name);
      for (i=0; i<8; ++i)
	if (r->h_aliases[i]) {
	  printf("alias \"%s\"; ",r->h_aliases[i]);
	} else break;
      if ((r->h_addr_list)[0]) {
	struct in_addr address;
	address = *((struct in_addr *) (r->h_addr_list)[0]);
	printf("addr %s; ", inet_ntoa(address));
      }
      putchar('\n');
    }
  }
  if (!i) {
    i=1;
    r=gethostbyname("prdownloads.sourceforge.net");
    goto again;
  }
#endif
#if 0
  char *tmp;
  printf("%lu\n",strtol("0xf0000000",&tmp,0));
#endif
#if 0
  struct mntent* me;
  FILE* f=fopen("/etc/fstab","r");
  while (me=getmntent(f)) {
    printf("%s\n",hasmntopt(me,"defaults"));
    printf("%s %s %s %s %d %d\n",me->mnt_fsname,me->mnt_dir,me->mnt_type,me->mnt_opts,me->mnt_freq,me->mnt_passno);
    break;
  }
#endif
#if 0
  char *tmp;
  printf("%x\n",strtol("0Xffff",&tmp,16));
#endif
/*  putchar('c');
  write(1,"fnord\n",6); */
#if 0
  struct addrinfo *ai;
//  getaddrinfo("xorn","22",0,&ai);
  puts(gai_strerror(getaddrinfo("xorn","22",0,&ai)));
#endif
#if 0
  struct hostent host,*res;
  char buf[4096];
  int fnord;

  gethostbyname2_r("nagus",AF_INET,&host,buf,4096,&res,&fnord);
#endif
#if 0
  char buf[128];
  strcpy(buf,"/tmp/fnord/foo.XXXXXXX");
  printf("%d\n",mkdtemp(buf));
  printf("%s\n",buf);
#endif
#if 0
  printf("%d\n",WEXITSTATUS(system("exit 17")));
#endif
#if 0
  fnord("fnord","foo\n","bar\n",0);
  assert(0);
#endif
#if 0
  printf("%hd %hhd\n",-5,-1234567);
#endif
#if 0
  printf("%d\n",fnmatch("*.o", "x.o", FNM_PATHNAME));
  printf("%d\n",fnmatch("a/b/*", "a/b/c/d", FNM_PATHNAME));
#endif
#if 0
  char buf[1024];
  int len;
  len=res_search("fu-berlin.de",ns_c_in,ns_t_ns,buf,sizeof(buf));
#endif
#if 0
  regex_t t;
  regmatch_t rm;
//  regcomp(&t,"^ *read",0);
  regcomp(&t,"\\<foo\\>",0);
  printf("%d\n",regexec(&t,"  blub foo,",1,&rm,0));
  printf("ofs %d\n",rm.rm_so);
#endif
#if 0
  char buf[100];
  printf("%d\n",fread(buf,1,0,stdin));
#endif
#if 0
  char buf[100];
  memset(buf,17,100);
  buf[0]=0;
  strncat(buf,"foobarbaz23",10);
  puts(buf);
#endif
#if 0
  int aflag = 0;
  int bflag = 0;
  char *cvalue = NULL;
  int index;
  int c;

  opterr = 1;

  while ((c = getopt (argc, argv, "abc:")) != -1)
    switch (c)
      {
      case 'a':
	aflag = 1;
	break;
      case 'b':
	bflag = 1;
	break;
      case 'c':
	cvalue = optarg;
	break;
      case '?':
	if (isprint (optopt))
	  fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	else
	  fprintf (stderr,
		  "Unknown option character `\\x%x'.\n",
		  optopt);
	return 1;
      default:
	abort ();
      }

  printf ("aflag = %d, bflag = %d, cvalue = %s\n",
	  aflag, bflag, cvalue);

  for (index = optind; index < argc; index++)
    printf ("Non-option argument %s\n", argv[index]);
  return 0;
#endif
#if 0
  char *t="foobar";
  char *c;
  char buf[1000];
  puts(strcat(strcpy(buf,"HOME="),t));
#endif
#if 0
  struct netent* n=getnetbyname("loopback");
  printf("%s %s\n",n->n_name,inet_ntoa(*(struct in_addr*)&n->n_net));
#endif
#if 0
  fprintf(stdout,"foo\n");
  sleep(1);
  fprintf(stdout,"bar");
  fprintf(stderr,"blonk");
  sleep(1);
  fprintf(stdout,"\rbz");
  sleep(1);
  fprintf(stdout,"\n");
  sleep(1);
#endif
#if 0
  sigset_t s;	/* sigsetops */

  sigemptyset(&s);
  sigaddset(&s,SIGCHLD);
  sigaddset(&s,SIGHUP);
  sigsuspend(&s);
#endif
#if 0
  char buf[1024];
  FILE *f=popen("uname -srm","r");
  fgets(buf,1023,f);
  pclose(f);
  write(1,buf,strlen(buf));
#endif
#if 0
  char type[64];
  char filename[256];
  int major,minor;
  int len;
  printf("%d\n",sscanf("GET / HTTP/1.0\r\n","%4[A-Z] %255[^ \t\r\n] HTTP/%d.%d",type,filename,&major,&minor));
  printf("%s %s %d %d\n",type,filename,major,minor);
#endif
#if 0
  char buf[100];
  char ip[16];
  memset(ip,0,16);
  printf("%p %p\n",inet_ntop(AF_INET6,ip,buf,100),buf);
  puts(buf);
#endif
#if 0
  struct addrinfo *ai;
  struct addrinfo hints;
  char buf[16];
  hints.ai_family = AF_UNSPEC;
  hints.ai_flags = AI_PASSIVE|AI_CANONNAME;
  hints.ai_socktype = SOCK_STREAM;
  printf("%d\n",getaddrinfo("xorn.continuum.local","ssh",0,&ai));
  while (ai) {
    printf("found host %s, port %d, family %s, socktype %s\n",ai->ai_canonname,
	   ntohs(ai->ai_family==AF_INET6?((struct sockaddr_in6*)ai->ai_addr)->sin6_port:
				   ((struct sockaddr_in*)ai->ai_addr)->sin_port),
	   ai->ai_family==AF_INET6?"PF_INET6":"PF_INET",
	   ai->ai_socktype==SOCK_STREAM?"SOCK_STREAM":"SOCK_DGRAM");
    {
      char buf[100];
      inet_ntop(ai->ai_family,ai->ai_family==AF_INET6?
		(char*)&(((struct sockaddr_in6*)ai->ai_addr)->sin6_addr):
		(char*)&(((struct sockaddr_in*)ai->ai_addr)->sin_addr),buf,100);
      printf("  %s\n",buf);
    }
    ai=ai->ai_next;
  }
#endif
#if 0
  int i=foo;
  printf("load average is %3.2f\n",0.0);
#endif
#if 0
  struct dirent **namelist;
  int n;

  n = scandir(".", &namelist, 0, alphasort);
  if (n < 0)
    perror("scandir");
  else {
    while(n--) {
      printf("%s\n", namelist[n]->d_name);
      free(namelist[n]);
    }
    free(namelist);
  }
#endif
#if 0
  char foo[10]="none,zlib";
  char *tmp,*tmp2=foo;
  while (tmp=strsep(&tmp2,",")) {
    puts(tmp);
  }
#endif
#if 0
  char foo[10];
  printf("%d %d\n",abs(-3),abs(23));
  strcpy(foo,"foo");
  strncat(foo,"barbaz",3);
  foo[6]=0;
  puts(foo);
#endif
#if 0
  struct hostent * host;
  struct in_addr i;

  host = gethostbyname2("nagus",AF_INET);

  if (!host)
    printf("host null\n");

  if (host && host->h_name) {
    printf("name %s\n", host->h_name);
  }
  if (host && (host->h_addr_list)[0]) {
    struct in_addr address;
    address = *((struct in_addr *) (host->h_addr_list)[0]);
    printf("addr %s\n", inet_ntoa(address));
  }
#endif
#if 0
  struct msgbuf bla;
  bla.mtype=0;
  bla.mtext[0]='x';
  msgsnd(327680,&bla,5,IPC_NOWAIT);
#endif
#if 0
  char buf[PATH_MAX];
  printf("%s\n",realpath("../../incoming/..///.zshrc",buf));
#endif
#if 0
  regex_t t;
  regcomp(&t,"^OpenSSH_2\\.5\\.[012]",5);
  printf("%d\n",regexec(&t,"OpenSSH_2.5.2p2",0,0,0));
#endif
#if 0
  float my_float = 9.2334;
  char buffer[100];

  sprintf(buffer, "%.2f", my_float);
  fprintf(stdout, "%s", buffer);
#endif
#if 0
  printf("%d\n",setenv("foo","bar",0));
  printf("%d\n",setenv("foo","bar",1));
  execlp("printenv","printenv","foo",0);
#endif
#if 0
  printf("%d\n",fnmatch("*c*","bin",0));
  if (!fnmatch("s*", "sub", 0))
    printf("s* sub\n");
  if (!fnmatch("s*", "glob", 0))
    printf("s* glob\n");
  if (!fnmatch("s*b", "sub", 0))
    printf("s*b sub\n");
  if (!fnmatch("s*h", "sub", 0))
    printf("s*h sub\n");
#endif
#if 0
  char*tmp;
  int n=asprintf(&tmp,"foo %s %d\n","bar",23);
  write(1,tmp,n);
  free(tmp);
#endif
#if 0
  struct passwd *p=getpwnam("leitner");
  struct spwd *s=getspnam("leitner");
  printf("%g\n",30.0123);
#endif
#if 0
  initgroups("root",100);
#endif
#if 0
  time_t t=time(0);
  printf("%lu\n",t);
  puts(asctime(localtime(&t)));
#endif
#if 0
  struct servent *foo=getservbyname("pop-3","tcp");
  if (foo)
    printf("found service %s on port %d\n",foo->s_name,foo->s_port);
#endif
#if 0
  char buf[128];
  strcpy(buf,"/tmp/blub/foo.XXXXXXX");
  printf("%d\n",mkstemp(buf));
  printf("%s\n",buf);
  unlink(buf);
#endif
#if 0
  char buf[512]="foo";
  strncat(buf,"barbaz",3);
  puts(buf);
#endif
#if 0
  time_t oink=time(0);
  struct tm *duh=localtime(&oink);
  strftime(buf,512,"%A %B %Y\n",duh);
  puts(buf);
#endif
#if 0
  struct in_addr bar;
  struct hostent *foo;
  inet_aton("160.45.10.8",&bar);
/*  foo=gethostbyname("zeit.fu-berlin.de"); */
  foo=gethostbyaddr(&bar,4,AF_INET);
  if (foo)
    printf("%s -> %s\n",foo->h_name,inet_ntoa(*(struct in_addr*)foo->h_addr));
/*  printf("%g %g\n",1e-10,1e10); */
#endif
#if 0
  double d=0.0;
  long long t=0x12345678ABCDEF01;
  d/=0.0;
  printf("%d %llx\n",__isnan(d),t,*(long long*)&d);
#endif
#if 0
#define SIZE 1000
  int array[SIZE],array2[SIZE];
  int i,j;
  long a,b,c;
  int *k;
  for (i=0; i<SIZE; ++i) array[i]=rand();
  memcpy(array2,array,sizeof(array));
  qsort(array,SIZE,sizeof(int),compint);
  for (i=0; i<SIZE-1; ++i)
    assert(array[i]>array[i+1]);
  k=bsearch(array+10,array,SIZE,sizeof(int),compint);
  printf("%d\n",*k);
#endif
#if 0
  printf("%p\n",malloc(0));
  qsort(array,2,sizeof(int),compint);
  for (i=0; i<SIZE; ++i)
    array[i]=rand();
  rdtscl(a);
  qsort(array,SIZE,sizeof(int),compint);
  rdtscl(b);
  j=array[LOOKFOR];
  res=bsearch(&j,array,SIZE,sizeof(int),compint);
  rdtscl(c);
  printf("%lu cycles sort, %lu cycles bsearch\n",b-a,c-b);
  for (i=0; i<SIZE-1; ++i)
    if (array[i]>array[i+1]) {
      printf("qsort does not work, index %d: %d > %d\n",i,array[i],array[i+1]);
      return 1;
    }
  if (*res!=j)
    printf("besearch does not work, returned %p (%d) instead of %p (%d)\n",res,res?*res:-1,array+LOOKFOR,j);
/*  printf("array={%d,%d,%d,%d,%d}\n",array[0],array[1],array[2],array[3],array[4]); */
#endif
#if 0
  struct in_addr duh;
  printf("%d\n",inet_aton(argv[1]?argv[1]:"10.0.0.1",&duh));
  printf("%x\n",duh.s_addr);
#endif
/*  printf("%-19s %10lu %9lu %9lu %3d%% %s\n","/dev/ide/host0/bus0/target0/lun0/part2",8393688,705683,1337084,85,"/"); */
#if 0
  char buf[100];
  fgets(buf,100,stdin); printf("got %d bytes\n",strlen(buf));
  fgets(buf,100,stdin); printf("got %d bytes\n",strlen(buf));
#endif
#if 0
  struct tm duh;
  time_t t;
  time(&t);
  gmtime_r(&t,&duh);
  printf("%s\n",asctime(&duh));
#endif
#if 0
  char buf[30];
  duh.tm_sec=42;
  duh.tm_min=23;
  duh.tm_hour=17;
  duh.tm_mday=2;
  duh.tm_mon=7;
  duh.tm_year=100;
  t=mktime(&duh);
  printf("%s\n",asctime_r(&duh,buf));
#endif
#if 0
  int i;
  for (i=0; i<5; i++) {
    fprintf(stdout,"first message\n");
    fprintf(stdout,"second message\n");
    fprintf(stdout,"third message\n");
    printf("foo %d\n",i);
  }
#endif
#if 0
  char buf[1024];
  sscanf("foo bar","%s",buf);
  printf("%s\n",buf);
#endif
#if 0
  mount("/dev/scsi/host0/bus0/target2/lun0/cd", "/cd", "iso9660", MS_MGC_VAL|MS_RDONLY, NULL);
  perror("mount");
#endif
#if 0
  char *t="<4>Linux version 2.4.0-test10 (leitner@hellhound) (gcc version 2.95.2 19991024 (release))";
  int i=strtol(t+1,&t,10);
  printf("%d %s\n",i,t);
#endif
#if 0
  char **tmp;
  putenv("A=foo");
  for (tmp=environ; *tmp; tmp++)
    puts(*tmp);
#endif
#if 0
  char buf[1024];
  printf("%d\n",fprintf(stderr,"duh\n"));
#endif
#if 0
  struct passwd *p=getpwuid(100);
  puts(p->pw_name);
#endif
#if 0
  int pid;
  char name[32];
  sscanf("1 (init","%d (%15c",&pid,name);
  printf("pid %d name %s\n",pid,name);
#endif
#if 0
  DIR *d=opendir("/proc");
  if (d) {
    struct dirent *D;
    while (D=readdir(d))
      puts(D->d_name);
    closedir(d);
  }
#endif
#if 0
  char buf[1024];
  int fd=open("/etc/passwd",0);
  pread(fd,buf,30,32);
  close(fd);
  write(1,buf,32);
#endif
#if 0
  char *argv[] = {"echo","foo",0};
  char buf[100];
  buf[5]='x';
  sprintf(buf,"foo\n");
  if (buf[5] == 'x')
    exit(0);
  else
    exit(1);
  execvp(argv[0],argv);
#endif
#if 0
  struct stat64 f;
  char buf[128];
  fstat64(0,&f);
  fprintf(stderr,"%d %d\n",f.st_size,sizeof(f));
  return 0;
#endif
#if 0
  FILE *f=fopen("foo","w");
  fputc('a',f);
  fputc('b',f);
  fputc('c',f);
#endif
/*  fprintf(stdout,"foo\n"); */
}
