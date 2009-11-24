#include <sys/types.h>
#include <sys/signal.h>

unsigned
sleep(unsigned secs) {
	extern time_t time (time_t *);
	time_t t = time(0);

	_alarm(secs);
	_pause();
	return (time(0) - t);
}
