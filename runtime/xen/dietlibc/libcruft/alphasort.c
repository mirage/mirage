#include <dirent.h>
#include <string.h>

int alphasort(const struct dirent **a, const struct dirent **b) {
  return strcmp((*a)->d_name,(*b)->d_name);
}
