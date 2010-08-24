#include <dirent.h>
#include <string.h>

int alphasort64(const struct dirent64 **a, const struct dirent64 **b) {
  return strcmp((*a)->d_name,(*b)->d_name);
}
