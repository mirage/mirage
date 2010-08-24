#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    FILE * fp;
    char * line = NULL;
    size_t len = 0;
    ssize_t read;
    fp = fopen("/etc/motd", "r");
    if (fp == NULL)
	  exit(EXIT_FAILURE);
    while ((read = getline(&line, &len, fp)) != -1) {
	  printf("Retrieved line of length %zu (n=%zu):\n", read, len);
	  printf("%s", line);
    }
    if (line)
	  free(line);
    return EXIT_SUCCESS;
}

