#include <xen/io/kbdif.h>
#include <xen/io/fbif.h>
#include <mini-os/wait.h>

/* from <linux/input.h> */
#ifndef BTN_LEFT
#define BTN_LEFT 0x110
#endif
#ifndef BTN_RIGHT
#define BTN_RIGHT 0x111
#endif
#ifndef BTN_MIDDLE
#define BTN_MIDDLE 0x112
#endif
#ifndef KEY_Q
#define KEY_Q 16
#endif
#ifndef KEY_MAX
#define KEY_MAX 0x1ff
#endif


struct kbdfront_dev;
struct kbdfront_dev *init_kbdfront(char *nodename, int abs_pointer);
#ifdef HAVE_LIBC
int kbdfront_open(struct kbdfront_dev *dev);
#endif

int kbdfront_receive(struct kbdfront_dev *dev, union xenkbd_in_event *buf, int n);
extern struct wait_queue_head kbdfront_queue;

void shutdown_kbdfront(struct kbdfront_dev *dev);


struct fbfront_dev *init_fbfront(char *nodename, unsigned long *mfns, int width, int height, int depth, int stride, int n);
#ifdef HAVE_LIBC
int fbfront_open(struct fbfront_dev *dev);
#endif

int fbfront_receive(struct fbfront_dev *dev, union xenfb_in_event *buf, int n);
extern struct wait_queue_head fbfront_queue;
void fbfront_update(struct fbfront_dev *dev, int x, int y, int width, int height);
void fbfront_resize(struct fbfront_dev *dev, int width, int height, int stride, int depth, int offset);

void shutdown_fbfront(struct fbfront_dev *dev);
