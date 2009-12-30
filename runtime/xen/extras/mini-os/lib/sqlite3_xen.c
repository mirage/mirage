#include <stdio.h>
#include <sqlite3.h>

int sqlite3_os_init(void) {
  printf("sqlite3_os_init\n");
  return SQLITE_OK;
}

int sqlite3_os_end(void) {
  printf("sqlite3_os_end\n");
  return SQLITE_OK;
}

