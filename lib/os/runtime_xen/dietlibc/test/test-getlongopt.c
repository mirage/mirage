#define _GNU_SOURCE
#include <unistd.h>
#include <getopt.h>
#include <stdio.h>

int test1;

struct option longopts[] = {
	{"long1", 0, 0, 'a'},
	{"long2", 0, &test1, 5},
	{"long3", 1, 0, 'b'},
	{"long4", 2, 0, 'c'},
	{ 0 }
};

int main(int argc, char **argv) {
	int longidx;
	int opt;
	char *b = "foo";
	char *c = "bar";
	int aseen = 0;
	
	while ((opt = getopt_long(argc, argv, "-ab:c::", longopts, &longidx)) != -1) {
		switch (opt) {
			case 'a':
				printf("a\n");
				aseen++;
				break;
			case 'b':
				printf("b\n");
				b = optarg;
				break;
			case 'c':
				printf("c\n");
				if (optarg)
					c = optarg;
				else
					c = "baz";
				break;
			case 0:
				printf("Null arg\n");
				break;
			default:
				printf("opt: %d\n", opt);
		}
	}

	printf("b: %s\nc: %s\naseen: %d\ntest1: %d\n", b, c, aseen, test1);
	return 0;
}

