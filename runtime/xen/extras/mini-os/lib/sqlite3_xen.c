#include <stdio.h>
#include <sqlite3.h>

#define VFS_NAME "mirage"

struct mirFile {
    sqlite3_io_methods const *pMethod;
};

static int mirOpen(
  sqlite3_vfs *pVfs,           /* The VFS for which this is the xOpen method */
  const char *zPath,           /* Pathname of file to be opened */
  sqlite3_file *pFile,         /* The file descriptor to be filled in */
  int flags,                   /* Input flags to control the opening */
  int *pOutFlags               /* Output flags returned to SQLite core */
) {
    return SQLITE_ERROR;
}

static int mirDelete(
  sqlite3_vfs *NotUsed,     /* VFS containing this as the xDelete method */
  const char *zPath,        /* Name of file to be deleted */
  int dirSync               /* If true, fsync() directory after deleting file */
) {
    return SQLITE_ERROR;
}

/*
** Test the existance of or access permissions of file zPath. The
** test performed depends on the value of flags:
**
**     SQLITE_ACCESS_EXISTS: Return 1 if the file exists
**     SQLITE_ACCESS_READWRITE: Return 1 if the file is read and writable.
**     SQLITE_ACCESS_READONLY: Return 1 if the file is readable.
**
** Otherwise return 0.
*/
static int mirAccess(
  sqlite3_vfs *NotUsed,   /* The VFS containing this xAccess method */
  const char *zPath,      /* Path of the file to examine */
  int flags,              /* What do we want to learn about the zPath file? */
  int *pResOut            /* Write result boolean here */
) {
    return SQLITE_ERROR;
}

/*
** Turn a relative pathname into a full pathname. The relative path
** is stored as a nul-terminated string in the buffer pointed to by
** zPath. 
**
** zOut points to a buffer of at least sqlite3_vfs.mxPathname bytes 
** (in this case, MAX_PATHNAME bytes). The full-path is written to
** this buffer before returning.
*/
static int mirFullPathname(
  sqlite3_vfs *pVfs,            /* Pointer to vfs object */
  const char *zPath,            /* Possibly relative input path */
  int nOut,                     /* Size of output buffer in bytes */
  char *zOut                    /* Output buffer */
) {
    return SQLITE_ERROR;
}

/*
** Write nBuf bytes of random data to the supplied buffer zBuf.
*/
static int mirRandomness(
  sqlite3_vfs *NotUsed, 
  int nBuf, 
  char *zBuf
) {
    return SQLITE_ERROR;
}

static int mirSleep(
  sqlite3_vfs *NotUsed, 
  int microseconds
) {
    return SQLITE_ERROR;
}

static int mirCurrentTime(
  sqlite3_vfs *NotUsed, 
  double *prNow
) {
    return SQLITE_ERROR;
}

static int mirGetLastError(
  sqlite3_vfs *NotUsed, 
  int NotUsed2, 
  char *NotUsed3
) {
  return SQLITE_ERROR;
}

struct sqlite3_vfs vfs = {
    1,                    /* iVersion */
    sizeof(struct mirFile),      /* szOsFile */
    1024,                 /* mxPathname */
    0,                    /* pNext */ 
    VFS_NAME,             /* zName */
    NULL,                 /* pAppData */
    mirOpen,              /* xOpen */
    mirDelete,            /* xDelete */
    mirAccess,            /* xAccess */
    mirFullPathname,      /* xFullPathname */
    NULL,                 /* xDlOpen */
    NULL,                 /* xDlError */
    NULL,                 /* xDlSym */
    NULL,                 /* xDlClose */
    mirRandomness,        /* xRandomness */
    mirSleep,             /* xSleep */
    mirCurrentTime,       /* xCurrentTime */
    mirGetLastError       /* xGetLastError */
};

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
