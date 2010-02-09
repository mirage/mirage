#include <stdlib.h>

static randbuf rand48buf;
#define A_0  0xE66D
#define A_1  0xDEEC
#define A_2  0x5
#define C 0xB
static randbuf a = { A_0, A_1, A_2 };
static unsigned short c = C;

static void calc_next(randbuf buf) {
	randbuf tmp;
	long t;
	t = buf[0] * a[0] + c;
	tmp[0] = t & 0xffff;
	tmp[1] = (t >> 16) & 0xffff;
	t = buf[1] * a[0] + buf[0] * a[1] + tmp[1];
	tmp[1] = t & 0xffff;
	tmp[2] = (t >> 16) & 0xffff;
	t = buf[2] * a[0] + buf[1] * a[1] + buf[0] * a[2] + tmp[2];
	tmp[2] = t & 0xffff;
	buf[0] = tmp[0];
	buf[1] = tmp[1];
	buf[2] = tmp[2];
}

double drand48(void) {
	return erand48(rand48buf);
}

long lrand48(void) {
	return nrand48(rand48buf);
}

long mrand48(void) {
	return jrand48(rand48buf);
}

void srand48(long seed) {
	rand48buf[1] = (seed >> 16) & 0xffff;
	rand48buf[2] = seed & 0xffff;
	rand48buf[0] = 0x330e;
	a[0] = A_0;
	a[1] = A_1;
	a[2] = A_2;
	c = C;
}

unsigned short *seed48(randbuf buf) {
	static randbuf oldx;
	int i;
	for (i = 0; i < 3; i++) {
		oldx[i] = rand48buf[i];
		rand48buf[i] = buf[i];
	}
	a[0] = A_0;
	a[1] = A_1;
	a[2] = A_2;
	c = C;
	return (unsigned short *)&oldx;
}

void lcong48(unsigned short param[7]) {
	int i;
	for (i = 0; i < 3; i++) {
		rand48buf[i] = param[i];
		a[i] = param[i + 3];
	}
	c = param[6];
}

long jrand48(randbuf buf) {
	long ret;
	ret = buf[2] << 16 | buf[1];
	calc_next(buf);
	return ret;
}

long nrand48(randbuf buf) {
	return jrand48(buf) & 0x7FFFFFFFL;
}

double erand48(randbuf buf) {
	double ret;
	ret = ((buf[0] / 65536.0 + buf[1]) / 65536.0 + buf[2]) / 65536.0;
	calc_next(buf);
	return ret;
}

