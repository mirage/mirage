extern end;

static void *curbrk = (char*)&end;

void *
sbrk(incr)
int incr; {
	extern int errno;
	extern int _brk(void *);
	void *ptr = curbrk;
	int t;

	if (incr == 0)
		return curbrk;
	t = _brk (curbrk + incr);
	if (t == -1 && errno)
		return (void *)-1;
	curbrk = ((char *)curbrk) + incr;
	return ptr;
}

