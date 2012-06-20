#include <stdio.h>
#include <regex.h>
#include <assert.h>
#include <string.h>

int main() {
  regex_t r;
  char buf[16*1024];
  int i;
  regmatch_t matches[10];
  memset(buf,'a',sizeof buf);
  strcpy(buf+sizeof(buf)-100," foo . .. bar\n");

  assert(regcomp(&r,"(|-.*)@fefe.de",REG_EXTENDED)==0);
  assert(regexec(&r,"@fefe.de",0,0,0)==0);
  regfree(&r);

  assert(regcomp(&r,"usenet-[0-9]{8}@fefe.de",REG_EXTENDED)==0);
  assert(regexec(&r,"usenet-12345678@fefe.de",0,0,0)==0);
  regfree(&r);

  assert(regcomp(&r,"(abuse|borland|bounceok|cdb|clickbank|der|dnscache|dsniff|gilda|myspace|password|postmaster|publicfile|qmail|qmaill|rfc2460|spam|stackguard|staroffice|susewindows|tdsl|true|vmware|web|yadocfaq|zeroseek)@fefe.de",REG_EXTENDED)==0);
  assert(regexec(&r,"abuse@fefe.de",0,0,0)==0);
  regfree(&r);

  assert(regcomp(&r,"@(ioctl.codeblau.de|fcntl.codeblau.de|knuth.codeblau.de|codeblau.de|lists.codeblau.de|code-blau.de|codeblau.com|code-blau.com|ccc.fefe.de|wegwerfdomain.de|fefes.wegwerfdomain.de|bewaff.net|rc23.rx|fnord.st|ist.schwervernetzt.de|kesim.(org|net|com)|tinydns.net|spiral-dynamics.org|hinke.org|2.0.1.0.8.5.6.0.1.0.0.2.ip6.int|eckner.org|mindbase.de|codeblau.walledcity.de)",REG_EXTENDED)==0);
  assert(regexec(&r,"abuse@fefe.de",0,0,0)==REG_NOMATCH);
  regfree(&r);

  assert(regcomp(&r,"^$",REG_EXTENDED)==0);
  assert(regexec(&r,"",0,0,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==0);
  regfree(&r);

  assert(regcomp(&r,"abracadabra$",REG_EXTENDED)==0);
  assert(regexec(&r,"abracadabracadabra",10,matches,0)==0);
  assert(matches[0].rm_so==7 && matches[0].rm_eo==18);
  regfree(&r);

  assert(regcomp(&r,"a...b",REG_EXTENDED)==0);
  assert(regexec(&r,"abababbb",10,matches,0)==0);
  assert(matches[0].rm_so==2 && matches[0].rm_eo==7);
  regfree(&r);

  assert(regcomp(&r,"XXXXXX",REG_EXTENDED)==0);
  assert(regexec(&r,"..XXXXXX",10,matches,0)==0);
  assert(matches[0].rm_so==2 && matches[0].rm_eo==8);
  regfree(&r);

  assert(regcomp(&r,"\\)",REG_EXTENDED)==0);
  assert(regexec(&r,"()",10,matches,0)==0);
  assert(matches[0].rm_so==1 && matches[0].rm_eo==2);
  regfree(&r);

  assert(regcomp(&r,"a]",REG_EXTENDED)==0);
  assert(regexec(&r,"a]a",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==2);
  regfree(&r);

  assert(regcomp(&r,"}",REG_EXTENDED)==0);
  assert(regexec(&r,"}",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"\\}",REG_EXTENDED)==0);
  assert(regexec(&r,"}",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"\\]",REG_EXTENDED)==0);
  assert(regexec(&r,"]",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"]",REG_EXTENDED)==0);
  assert(regexec(&r,"]",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"}",REG_EXTENDED)==0);
  assert(regexec(&r,"}",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"{",0)==0);
  assert(regexec(&r,"{",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"^a",REG_EXTENDED)==0);
  assert(regexec(&r,"ax",10,matches,0)==0);
  assert(matches[0].rm_so==0 && matches[0].rm_eo==1);
  regfree(&r);

  assert(regcomp(&r,"\\^a",REG_EXTENDED)==0);
  assert(regexec(&r,"a^a",10,matches,0)==0);
  assert(matches[0].rm_so==1 && matches[0].rm_eo==3);
  regfree(&r);

  assert(regcomp(&r,"(gilda|oskar|leitner(-[^@]+|))@home.fefe.de",REG_EXTENDED)==0);
  assert(regexec(&r,"leitner@home.fefe.de",10,matches,0)==0);
  regfree(&r);

  assert(regcomp(&r,"^chello[0-9]*.chello.[a-z][a-z]$",REG_EXTENDED)==0);
  assert(regexec(&r,"chello089078194199.chello.pl",10,matches,0)==0);
  regfree(&r);

  assert(regcomp(&r,"(satel.com|kievnet.com|dn|merlin.net|inetcom.com|zdn.gov|terabit.com|od|odessa|elencom.net|uz|syndicate.org|tvcom.net|dn|qt.net|b-net.com).ua",REG_EXTENDED|REG_ICASE|REG_NOSUB)==0);
  assert(regexec(&r,"mail.b-net.com.ua",0,NULL,0)==0);
  regfree(&r);

  assert(regcomp(&r,"\\(foo\\)bar\\1",0)==0);
  assert(regexec(&r,"foobarfoo",10,matches,0)==0);
  regfree(&r);

#if 0
  printf("regcomp %d\n",regcomp(&r,"\\.( ? ? ?\\.)*\\.",REG_EXTENDED|REG_NOSUB));
  printf("regexec %d\n",regexec(&r,buf,1,0,0));
  regfree(&r);
#endif
#if 0
  printf("regcomp %d\n",regcomp(&r,"^(ksambakdeplugin|mnemisis|kylixxmlrpclib|ripunix|featurekong)@freshmeat.net",REG_EXTENDED|REG_NEWLINE|REG_ICASE));
  {
    int canary[100];
    for (i=0; i<100; ++i) canary[i]=i;
    printf("regexec %d\n",regexec(&r,"mnemisis@freshmeat.net",2,matches,0));
    for (i=0; i<100; ++i) assert(canary[i]==i);
  }
  regfree(&r);
  for (i=0; i<10; ++i) {
    printf("%s(%d %d)",i?", ":" -> ",matches[i].rm_so,matches[i].rm_eo);
  }
  printf("\n");
#endif
#if 0
  printf("regcomp %d\n",regcomp(&r,"^(a|b|c|d|e)@freshmeat.net",REG_EXTENDED|REG_NEWLINE|REG_NOSUB|REG_ICASE));
  printf("regexec %d\n",regexec(&r,"a@freshmeat.net",1,0,0));
#endif
#if 0
  printf("regcomp %d\n",regcomp(&r,"^([A-Za-z ]+>|[]>:|}][]>:|}]*)",REG_EXTENDED|REG_NEWLINE|REG_NOSUB|REG_ICASE));
  printf("regexec %d\n",regexec(&r,"fnord",1,0,0));
#endif
#if 0
  printf("regcomp %d\n",regcomp(&r,"^Subject:",REG_EXTENDED|REG_ICASE));
  printf("regexec %d\n",regexec(&r,"Subject: duh",1,0,0));
#endif
#if 0
  printf("regcomp %d\n",regcomp(&r,"^To:([^@]*)?$",REG_EXTENDED|REG_ICASE|REG_NOSUB));
  printf("regexec %d\n",regexec(&r,"To: <Undisclosed Recipients>",1,0,0));
  regfree(&r);
#endif
  return 0;
}
