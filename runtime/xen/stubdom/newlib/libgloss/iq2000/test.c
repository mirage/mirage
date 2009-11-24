#include <stdio.h>

static void
send_msg1 (void)
{
  static char msg[] = "Hello World\r\n";
  write(1, msg, strlen (msg));
}

static void
send_msg2 (void)
{
  static char msg[] = "Goodnight Irene\r\n";
  write(1, msg, strlen (msg));
}

static void
delay (void)
{
  int i;

  for (i = 0; i < 1000000; i++)
    ;
}

int
main(int argc, char *argv[])
{
  int i, j;
  for (i = 0; i < 10; i++)
    {
      send_msg1 ();
      delay ();
      send_msg2 ();
    }
  return 0;
}


