#ifndef __X86_BZIMAGE_H__
#define __X86_BZIMAGE_H__

#include <xen/config.h>

int __init bzimage_headroom(char *image_start, unsigned long image_length);

int __init bzimage_parse(char *image_base,
			char **image_start,
			unsigned long *image_len);

#endif /* __X86_BZIMAGE_H__ */
