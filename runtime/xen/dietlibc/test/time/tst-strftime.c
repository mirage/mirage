#include <stdio.h>
#include <stdlib.h>
#include <time.h>


static struct
{
  const char *fmt;
  size_t min;
  size_t max;
} tests[] =
  {
    { "%2000Y", 2000, 4000 },
    { "%02000Y", 2000, 4000 },
    { "%_2000Y", 2000, 4000 },
    { "%-2000Y", 2000, 4000 },
  };
#define ntests (sizeof (tests) / sizeof (tests[0]))


int main (void) {
  size_t cnt;
  int result = 0;

  time_t tnow = time (NULL);
  struct tm *now = localtime (&tnow);

  for (cnt = 0; cnt < ntests; ++cnt)
    {
      size_t size = 0;
      int res;
      char *buf = NULL;

      do
	{
	  size += 500;
	  buf = (char *) realloc (buf, size);
	  if (buf == NULL)
	    {
	      puts ("out of memory");
	      exit (1);
	    }

	  res = strftime (buf, size, tests[cnt].fmt, now);
	  if (res != 0)
	    break;
	}
      while (size < tests[cnt].max);

      if (res == 0)
	{
	  printf ("%Zu: %s: res == 0 despite size == %Zu\n",
		  cnt, tests[cnt].fmt, size);
	  result = 1;
	}
      else if (size < tests[cnt].min)
	{
	  printf ("%Zu: %s: size == %Zu was enough\n",
		  cnt, tests[cnt].fmt, size);
	  result = 1;
	}
      else
	printf ("%Zu: %s: size == %Zu: OK\n", cnt, tests[cnt].fmt, size);

      free (buf);
    }

  return result;
}

