extern int _end;

static char *end_of_data = (char *) &_end;

char *
_sbrk (int delta) {
	char *ptr = end_of_data;

	end_of_data += delta;
	return ptr;
}

