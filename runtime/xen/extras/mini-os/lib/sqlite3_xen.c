#include <stdio.h>
#include <string.h>
#include <sqlite3.h>

#define VFS_NAME "mirage"

static int 
mirClose(sqlite3_file *file)
{
  printf("mirClose\n");
  return SQLITE_ERROR;
}

/*
** Read data from a file into a buffer.  Return SQLITE_OK if all
** bytes were read successfully and SQLITE_IOERR if anything goes
** wrong.
*/
static int 
mirRead(sqlite3_file *id, void *pBuf, int amt, sqlite3_int64 offset) {
  printf("mirRead\n");
  return SQLITE_ERROR;
}

/*
** Write data from a buffer into a file.  Return SQLITE_OK on success
** or some other error code on failure.
*/
static int
mirWrite(sqlite3_file *id, const void *pBuf, int amt, sqlite3_int64 offset) {
  printf("mirWrite\n");
  return SQLITE_ERROR;
}

/*
** Truncate an open file to a specified size
*/
static int 
mirTruncate(sqlite3_file *id, sqlite3_int64 nByte) {
  printf("mirTruncate\n");
  return SQLITE_ERROR;
}

/*
** Make sure all writes to a particular file are committed to disk.
**
** If dataOnly==0 then both the file itself and its metadata (file
** size, access time, etc) are synced.  If dataOnly!=0 then only the
** file data is synced.
**
*/
static int 
mirSync(sqlite3_file *id, int flags) {
  int isDataOnly = (flags & SQLITE_SYNC_DATAONLY);
  int isFullSync = (flags & 0x0F) == SQLITE_SYNC_FULL;
  printf("mirSync: data=%d fullsync=%d\n", isDataOnly, isFullSync);
  return SQLITE_ERROR;
}

/*
** Determine the current size of a file in bytes
*/
static int 
mirFileSize(sqlite3_file *id, sqlite3_int64 *pSize) {
  printf("mirFileSize\n");
  return SQLITE_ERROR;
}

static int
mirCheckLock(sqlite3_file *NotUsed, int *pResOut) {
  printf("mirCheckLock\n");
  *pResOut = 0;
  return SQLITE_OK;
}

static int
mirLock(sqlite3_file *NotUsed, int NotUsed2) {
  printf("mirLock\n");
  return SQLITE_OK;
}

static int 
mirUnlock(sqlite3_file *NotUsed, int NotUsed2) {
  printf("mirUnlock\n");
  return SQLITE_OK;
}

/*
** Information and control of an open file handle.
*/
static int
mirFileControl(sqlite3_file *id, int op, void *pArg) {
  printf("mirFileControl\n");
  return SQLITE_ERROR;
}

/*
** Return the sector size in bytes of the underlying block device for
** the specified file. This is almost always 512 bytes, but may be
** larger for some devices.
**
** SQLite code assumes this function cannot fail. It also assumes that
** if two files are created in the same file-system directory (i.e.
** a database and its journal file) that the sector size will be the
** same for both.
*/
static int 
mirSectorSize(sqlite3_file *NotUsed) {
  /* XXX: match to blkfront sector size */
  printf("mirSectorSize\n");
  return 512;
}

/*
** Return the device characteristics for the file. This is always 0 for unix.
*/
static int 
mirDeviceCharacteristics(sqlite3_file *NotUsed) {
  printf("mirDeviceCharacteristics\n");
  return 0;
}

static const sqlite3_io_methods mirIoMethods = {
   1,                          /* iVersion */
   mirClose,                   /* xClose */
   mirRead,                    /* xRead */
   mirWrite,                   /* xWrite */
   mirTruncate,                /* xTruncate */
   mirSync,                    /* xSync */
   mirFileSize,                /* xFileSize */
   mirLock,                    /* xLock */
   mirUnlock,                  /* xUnlock */
   mirCheckLock,               /* xCheckReservedLock */
   mirFileControl,             /* xFileControl */
   mirSectorSize,              /* xSectorSize */
   mirDeviceCharacteristics    /* xDeviceCapabilities */
};

struct mirFile {
    sqlite3_io_methods const *pMethod;
};

/** Open the file zPath.
** 
**     ReadWrite() ->     (READWRITE | CREATE)
**     ReadOnly()  ->     (READONLY) 
**     OpenExclusive() -> (READWRITE | CREATE | EXCLUSIVE)
**
** The old OpenExclusive() accepted a boolean argument - "delFlag". If
** true, the file was configured to be automatically deleted when the
** file handle closed. To achieve the same effect using this new 
** interface, add the DELETEONCLOSE flag to those specified above for 
** OpenExclusive().
*/

static int mirOpen(
  sqlite3_vfs *pVfs,           /* The VFS for which this is the xOpen method */
  const char *zPath,           /* Pathname of file to be opened */
  sqlite3_file *pFile,         /* The file descriptor to be filled in */
  int flags,                   /* Input flags to control the opening */
  int *pOutFlags               /* Output flags returned to SQLite core */
) {
    int eType = flags & 0xFFFFFF00;  /* Type of file to open */
    printf("mirOpen: type ");
    switch (eType) {
    case SQLITE_OPEN_MAIN_DB:
      printf("main_db");
      break;
    case SQLITE_OPEN_MAIN_JOURNAL:
      printf("main_journal");
      break;
    case SQLITE_OPEN_TEMP_DB:
      printf("temp_db");
      break;
    case SQLITE_OPEN_TEMP_JOURNAL:
      printf("temp_journal");
      break;
    case SQLITE_OPEN_TRANSIENT_DB:
      printf("transient_db");
      break;
    case SQLITE_OPEN_SUBJOURNAL:
      printf("subjournal");
      break;
    case SQLITE_OPEN_MASTER_JOURNAL:
      printf("master_journal");
      break;
    default:
      printf("???");
    }
    printf(".\n");
    if (eType != SQLITE_OPEN_MAIN_DB)
      return SQLITE_ERROR;
    return SQLITE_ERROR;   
}

static int mirDelete(
  sqlite3_vfs *NotUsed,     /* VFS containing this as the xDelete method */
  const char *zPath,        /* Name of file to be deleted */
  int dirSync               /* If true, fsync() directory after deleting file */
) {
    printf("mirDeleteOpen\n");
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
    printf("mirAccess\n");
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
    printf("mirFullPathname\n");
    strcpy(zOut, zPath);
    return SQLITE_OK;
}

/*
** Write nBuf bytes of random data to the supplied buffer zBuf.
*/
static int mirRandomness(
  sqlite3_vfs *NotUsed, 
  int nBuf, 
  char *zBuf
) {
    printf("mirRandomness\n");
    return SQLITE_ERROR;
}

static int mirSleep(
  sqlite3_vfs *NotUsed, 
  int microseconds
) {
    printf("mirSleep\n");
    return SQLITE_ERROR;
}

static int mirCurrentTime(
  sqlite3_vfs *NotUsed, 
  double *prNow
) {
    printf("mirCurrentTime\n");
    return SQLITE_ERROR;
}

static int mirGetLastError(
  sqlite3_vfs *NotUsed, 
  int NotUsed2, 
  char *NotUsed3
) {
  printf("mirGetLastError\n");
  return SQLITE_ERROR;
}

struct sqlite3_vfs mirVfs = {
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
  int rc;
  printf("sqlite3_os_init: ");
  rc = sqlite3_vfs_register(&mirVfs, 1);
  if (rc != SQLITE_OK) {
    printf("error registering VFS\n");
  } else {
    printf("ok\n");
  }
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
