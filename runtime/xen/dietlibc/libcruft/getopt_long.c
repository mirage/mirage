#include <string.h>
#include <getopt.h>

static void getopterror(int which) {
  static char error1[]="Unknown option `-x'.\n";
  static char error2[]="Missing argument for `-x'.\n";
  if (opterr) {
    if (which) {
      error2[23]=optopt;
      write(2,error2,28);
    } else {
      error1[17]=optopt;
      write(2,error1,22);
    }
  }
}

int getopt_long(int argc, char * const argv[], const char *optstring,
		const struct option *longopts, int *longindex) {
  static int lastidx,lastofs;
  char *tmp;
  if (optind==0) { optind=1; lastidx=0; }	/* whoever started setting optind to 0 should be shot */
again:
  if (*optstring == '-' && optind<argc && *argv[optind]!='-') {
    optarg=argv[optind];
    ++optind;
    return 1;
  }
  if (optind>=argc || !argv[optind] || *argv[optind]!='-' || argv[optind][1]==0)
    return -1;
  if (argv[optind][1]=='-' && argv[optind][2]==0) {
    ++optind;
    return -1;
  }
  if (argv[optind][1]=='-') {	/* long option */
    char* arg=argv[optind]+2;
    char* max=strchr(arg,'=');
    const struct option* o;
    const struct option* match=0;
    if (!max) max=arg+strlen(arg);
    for (o=longopts; o->name; ++o) {
      size_t tlen=max-arg;
      if (!strncmp(o->name,arg,tlen)) {	/* match */
	if (strlen(o->name)==tlen) {
	  match=o;	/* perfect match, not just prefix */
	  break;
	}
	if (!match)
	  match=o;
	else
	  /* Another imperfect match. */
	  match=(struct option*)-1;
      }
    }
    if (match!=(struct option*)-1 && (o=match)) {
      if (longindex) *longindex=o-longopts;
      if (o->has_arg>0) {
	if (*max=='=')
	  optarg=max+1;
	else {
	  optarg=argv[optind+1];
	  if (!optarg && o->has_arg==1) {	/* no argument there */
	    if (*optstring==':') return ':';
	    write(2,"argument required: `",20);
	    write(2,arg,(size_t)(max-arg));
	    write(2,"'.\n",3);
	    ++optind;
	    return '?';
	  }
	  ++optind;
	}
      }
      ++optind;
      if (o->flag)
	*(o->flag)=o->val;
      else
	return o->val;
      return 0;
    }
    if (*optstring==':') return ':';
    write(2,"invalid option `",16);
    write(2,arg,(size_t)(max-arg));
    write(2,"'.\n",3);
    ++optind;
    return '?';
  }
  if (lastidx!=optind) {
    lastidx=optind; lastofs=0;
  }
  optopt=argv[optind][lastofs+1];
  if ((tmp=strchr(optstring,optopt))) {
    if (*tmp==0) {	/* apparently, we looked for \0, i.e. end of argument */
      ++optind;
      goto again;
    }
    if (tmp[1]==':') {	/* argument expected */
      if (tmp[2]==':' || argv[optind][lastofs+2]) {	/* "-foo", return "oo" as optarg */
	if (!*(optarg=argv[optind]+lastofs+2)) optarg=0;
	goto found;
      }
      optarg=argv[optind+1];
      if (!optarg) {	/* missing argument */
	++optind;
	if (*optstring==':') return ':';
	getopterror(1);
	return ':';
      }
      ++optind;
    } else {
      ++lastofs;
      return optopt;
    }
found:
    ++optind;
    return optopt;
  } else {	/* not found */
    getopterror(0);
    ++optind;
    return '?';
  }
}
