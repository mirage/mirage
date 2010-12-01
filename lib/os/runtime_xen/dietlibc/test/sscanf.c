#include <stdio.h>
#include <string.h>

int main() {
  char server_version_string[]="SSH-1.99-OpenSSH_2.9p2\n";
  int remote_major, remote_minor;
  char remote_version[1000];
  long a,b,c;
  if (sscanf(server_version_string, "SSH-%d.%d-%[^\n]\n",
	    &remote_major, &remote_minor, remote_version) != 3) return 1;
  if (remote_major!=1 || remote_minor!=99 || strcmp(remote_version,"OpenSSH_2.9p2"))
    return 1;
//  printf("%d.%d.%.100s\n",remote_major,remote_minor,remote_version);
  if (sscanf("000000013637d16600007b21","%8lx%8lx%8lx",&a,&b,&c)!=3) return 1;
  if (a != 1 || b != 0x3637d166 || c !=0x7b21) return 1;
  return 0;
}
