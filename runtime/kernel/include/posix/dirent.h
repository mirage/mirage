#ifndef _POSIX_DIRENT_H
#define _POSIX_DIRENT_H

#include <stdint.h>

struct dirent {
        char *d_name;
};

typedef struct {
        struct dirent dirent;
        char *name;
        int32_t offset;
        char **entries;
        int32_t curentry;
        int32_t nbentries;
        int has_more;
} DIR;

DIR *opendir(const char *name);
struct dirent *readdir(DIR *dir);
int closedir(DIR *dir);

#endif /* _POSIX_DIRENT_H */
