#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

main() {
  char buf[1024];

  realpath("fnord",buf);
  puts(buf);
  mkdir("foo",0755);
  symlink("foo","bar");
  close(open("foo/blah",O_WRONLY|O_CREAT,0700));
  realpath("bar/blah",buf);
  puts(buf);
  symlink("..","foo/blub");
  realpath("bar/blub/foo/blub",buf);
  puts(buf);
  unlink("foo/blub");
  unlink("foo/blah");
  rmdir("foo");
  unlink("bar");
}
