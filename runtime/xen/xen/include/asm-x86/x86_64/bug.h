#ifndef __X86_64_BUG_H__
#define __X86_64_BUG_H__

struct bug_frame_str {
    unsigned char mov;
    signed int str_disp;
} __attribute__((packed));
#define bug_str(b, rip) ((const char *)(rip) + (b).str_disp)
#define BUG_STR(n) "; movl %" #n " - ., %%esp"

#endif /* __X86_64_BUG_H__ */
