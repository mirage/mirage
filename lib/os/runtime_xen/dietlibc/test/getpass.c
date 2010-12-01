#include <stdio.h>
#include <unistd.h>

int main() {
  puts(getpass("Password: "));
  return 0;
}
