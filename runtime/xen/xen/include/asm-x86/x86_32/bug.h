#ifndef __X86_32_BUG_H__
#define __X86_32_BUG_H__

struct bug_frame_str {
    unsigned char mov;
    unsigned long str;
} __attribute__((packed));
#define bug_str(b, eip) ((const char *)(b).str)
#define BUG_STR(n) "; movl %" #n ", %%esp"

#endif /* __X86_32_BUG_H__ */
