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

void sqlite3_test(void) {
  sqlite3 *db;
  int ret;
  char *errmsg;
  ret = sqlite3_open("test.db", &db);
  if (ret) {
     printf("sqlite3_open error: %s\n", sqlite3_errmsg(db));
  } else {
     ret = sqlite3_exec(db, "create table foo (bar TEXT)", NULL, NULL, &errmsg);
     if (ret) {
       printf("sqlite3_exec: %s\n", sqlite3_errmsg(db));
     }
     ret = sqlite3_close(db);
  }
}
