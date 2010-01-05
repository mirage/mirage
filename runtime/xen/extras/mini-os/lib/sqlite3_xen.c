/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdio.h>
#include <mini-os/types.h>
#include <mini-os/xmalloc.h>
#include <string.h>
#include <sqlite3.h>
#include <ctype.h>
#include <mini-os/blkfront.h>

#define VFS_NAME "mirage"

#undef DEBUG_MIRIO

#ifdef DEBUG_MIRIO
#define SQLDEBUG printf
#else
#define SQLDEBUG if (0) printf
#endif

/* First sector of VBD is used for database metadata */
#define DB_NAME_MAXLENGTH 32
struct db_metadata {
  uint32_t version;
  uint64_t size;
  char name[DB_NAME_MAXLENGTH];
};

/* Mirage file structure, which records the IO callbacks and 
   blkfront device pointers for the db */
struct sqlite3_mir_file {
    const struct sqlite3_io_methods *pMethods;
    struct blkfront_dev *dev;
    struct blkfront_info info;
    struct db_metadata *meta;
};

static int 
mirClose(struct sqlite3_file *id)
{
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  SQLDEBUG("mirClose: START\n");
  shutdown_blkfront(mf->dev);
  if (mf->meta)
    free(mf->meta);
  SQLDEBUG("mirClose: OK\n");
  return SQLITE_OK;
}

/* Write database metadata to the first sector of the block device.
   Buffer must have come from readMetadata */
static void
writeMetadata(struct sqlite3_mir_file *mf)
{
  struct blkfront_aiocb req;
  bzero(&req, sizeof(struct blkfront_aiocb));
  ASSERT(mf->info.sector_size >= sizeof(struct db_metadata));
  SQLDEBUG("writeMetadata: ");
  req.aio_dev = mf->dev;
  req.aio_buf = (void *)mf->meta;
  req.aio_nbytes = mf->info.sector_size;
  req.aio_offset = 0;
  req.data = &req;
  blkfront_write(&req);
  SQLDEBUG(" OK\n");
}

/* Read database metadata from first sector of blk device.
   If it is uninitialized, then set the version field and
   sync it to disk. */
static void
readMetadata(struct sqlite3_mir_file *mf)
{
  struct blkfront_aiocb req;
  int ssize = mf->info.sector_size;
  bzero(&req, sizeof(struct blkfront_aiocb));
  ASSERT(ssize >= sizeof(struct db_metadata));
  SQLDEBUG("readMetadata: ");
  req.aio_dev = mf->dev;
  req.aio_buf = _xmalloc(ssize, ssize);
  req.aio_nbytes = ssize;
  req.aio_offset = 0;
  req.data = &req;
  blkfront_read(&req);
  mf->meta = (struct db_metadata *)req.aio_buf;
  if (mf->meta->version == 0) {
    SQLDEBUG(" NEW\n");
    mf->meta->version = 1;
    strcpy(mf->meta->name, "unknown");
    writeMetadata(mf);
  } else
    SQLDEBUG(" '%s' v=%lu sz=%Lu OK\n", mf->meta->name, mf->meta->version, mf->meta->size);
#ifdef DEBUG_MIRIO
  printf("readMetadata: ");
  for (int i = 0; i < ssize; i++) printf("%d ", ((char *)(req.aio_buf))[i]);
  printf("\n");
#endif
}

/*
** Read data from a file into a buffer.  Return SQLITE_OK if all
** bytes were read successfully and SQLITE_IOERR if anything goes
** wrong.
*/
static int 
mirRead(sqlite3_file *id, void *pBuf, int amt, sqlite3_int64 offset) {
  struct blkfront_aiocb *req;
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  int ssize = mf->info.sector_size;
  uint64_t sector_offset;
  uint64_t start_sector, nsectors, nbytes;

  /* Our reads to blkfront must be sector-aligned, so fix up if needed */
  sector_offset = offset % ssize;
  /* Add 1 to start sector to skip metadata block */
  start_sector = 1 + (offset / ssize);
  nsectors = (amt + sector_offset + ssize) / ssize;
  nbytes = nsectors * ssize;
 
  SQLDEBUG("mirRead: off=%Lu amt=%d start_sector=%Lu nsectors=%Lu nbytes=%Lu\n", offset, amt, start_sector, nsectors, nbytes); 
  req = xmalloc(struct blkfront_aiocb);
  bzero(req, sizeof(struct blkfront_aiocb));
  req->aio_dev = mf->dev;
  req->aio_buf = _xmalloc(nbytes, ssize);
  bzero(req->aio_buf, nbytes);
  req->aio_nbytes = nbytes;
  req->aio_offset = start_sector * ssize;
  req->data = req;

  /* XXX modify blkfront.c:blkfront_io to return error code if any */
  blkfront_read(req);
  bcopy(req->aio_buf + sector_offset, pBuf, amt);
  free(req->aio_buf);
  free(req);
#ifdef DEBUG_MIRIO
  printf("mirRead: ");
  for (int i = 0; i < amt; i++) printf("%d ", ((char *)pBuf)[i]);
  printf("\n");
#endif
  return SQLITE_OK;
}

/*
** Write data from a buffer into a file.  Return SQLITE_OK on success
** or some other error code on failure.
*/
static int
mirWrite(sqlite3_file *id, const void *pBuf, int orig_amt, sqlite3_int64 offset) {
  struct blkfront_aiocb *req;
  uint64_t sector, nsectors, nbytes;
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  int ssize = mf->info.sector_size;
  int amt = orig_amt;

  SQLDEBUG("mirWrite: amt=%d off=%Lu\n", orig_amt, offset);
  /* for small writes, round up to a sector and assume we are extending the file */
  if (amt < ssize) {
    ASSERT(offset + amt > mf->meta->size);
    amt = ssize;
  }

  /* Writes must be sector-aligned */
  ASSERT(offset % ssize == 0);

  /* Add 1 to sector to skip metadata block */
  sector = 1 + (offset / ssize);

  nsectors = amt / ssize;
  nbytes = nsectors * ssize;
  SQLDEBUG("mirWrite: sector=%Lu nsectors=%Lu nbytes=%Lu\n", sector, nsectors, nbytes); 

  req = xmalloc(struct blkfront_aiocb);
  bzero(req, sizeof(struct blkfront_aiocb));

  req->aio_dev = mf->dev;
  req->aio_buf = _xmalloc(nbytes, ssize);
  req->aio_nbytes = nbytes;
  req->aio_offset = sector * ssize;
  req->data = req;
  bzero(req->aio_buf, nbytes);
  bcopy(pBuf, req->aio_buf, orig_amt);
  /* XXX modify blkfront.c:blkfront_io to return error code if any */
  blkfront_write(req);
#ifdef DEBUG_MIRIO
  printf("mirWrite: ");
  for (int i = 0; i < amt; i++) printf("%Lx ", ((char *)pBuf)[i]);
  printf("\n");
#endif
  /* extend file size in metadata if necessary */
  if (req->aio_offset + req->aio_nbytes > mf->meta->size) {
    mf->meta->size = req->aio_offset + req ->aio_nbytes;
    writeMetadata(mf);
  }
  free(req->aio_buf);
  free(req);
  return SQLITE_OK;
}

/*
** Truncate an open file to a specified size
*/
static int 
mirTruncate(sqlite3_file *id, sqlite3_int64 nByte) {
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  mf->meta->size = nByte;
  writeMetadata(mf);
  SQLDEBUG("mirTruncate: %Lu OK\n", nByte);
  return SQLITE_OK;
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
  //int isDataOnly = (flags & SQLITE_SYNC_DATAONLY);
  //int isFullSync = (flags & 0x0F) == SQLITE_SYNC_FULL;
  //printf("mirSync: data=%d fullsync=%d OK LIED\n", isDataOnly, isFullSync);
  return SQLITE_OK;
}

/*
** Determine the current size of a file in bytes
*/
static int 
mirFileSize(sqlite3_file *id, sqlite3_int64 *pSize) {
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  ASSERT(mf->meta != NULL);
  SQLDEBUG("mirFileSize: %Lu OK\n", mf->meta->size);
  *pSize = mf->meta->size;
  return SQLITE_OK;
}

static int
mirCheckLock(sqlite3_file *NotUsed, int *pResOut) {
  //printf("mirCheckLock: OK\n");
  *pResOut = 0;
  return SQLITE_OK;
}

static int
mirLock(sqlite3_file *NotUsed, int NotUsed2) {
  //printf("mirLock: OK\n");
  return SQLITE_OK;
}

static int 
mirUnlock(sqlite3_file *NotUsed, int NotUsed2) {
  //printf("mirUnlock: OK\n");
  return SQLITE_OK;
}

/*
** Information and control of an open file handle.
*/
static int
mirFileControl(sqlite3_file *id, int op, void *pArg) {
  SQLDEBUG("mirFileControl: ERR\n");
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
mirSectorSize(sqlite3_file *id) {
  struct sqlite3_mir_file *mf = (struct sqlite3_mir_file *)id;
  int s = mf->info.sector_size;
  SQLDEBUG("mirSectorSize: %d OK\n", s);
  return s;
}

/*
** Return the device characteristics for the file.
*/
static int 
mirDeviceCharacteristics(sqlite3_file *NotUsed) {
  SQLDEBUG("mirDeviceCharacteristics: SQLITE_IOCAP_SAFE_APPEND\n");
  return SQLITE_IOCAP_SAFE_APPEND;
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
    struct sqlite3_mir_file *pMirFile = (struct sqlite3_mir_file *)pFile;
    char *nodename = NULL;

    SQLDEBUG("mirOpen: path=%s type ", zPath);
    switch (eType) {
    case SQLITE_OPEN_MAIN_DB:
      /* XXX hardcoded xenstore nodenames for now */
      SQLDEBUG("main_db");
      nodename="device/vbd/51713";
      break;
    case SQLITE_OPEN_MAIN_JOURNAL:
      SQLDEBUG("main_journal");
      nodename="device/vbd/51714";
      break;
    case SQLITE_OPEN_TEMP_DB:
      SQLDEBUG("temp_db");
      break;
    case SQLITE_OPEN_TEMP_JOURNAL:
      SQLDEBUG("temp_journal");
      break;
    case SQLITE_OPEN_TRANSIENT_DB:
      SQLDEBUG("transient_db");
      break;
    case SQLITE_OPEN_SUBJOURNAL:
      SQLDEBUG("subjournal");
      break;
    case SQLITE_OPEN_MASTER_JOURNAL:
      SQLDEBUG("master_journal");
      break;
    default:
      SQLDEBUG("???");
    }

    if (eType != SQLITE_OPEN_MAIN_DB && eType != SQLITE_OPEN_MAIN_JOURNAL) {
      SQLDEBUG(" ERR\n");
      return SQLITE_ERROR;
    } else {
      SQLDEBUG(" OK\n");
      ASSERT(nodename != NULL);
      pMirFile->pMethods = &mirIoMethods;
      pMirFile->dev = init_blkfront(nodename, &pMirFile->info);
      readMetadata(pMirFile);
      return SQLITE_OK;
    }
}

static int mirDelete(
  sqlite3_vfs *NotUsed,     /* VFS containing this as the xDelete method */
  const char *zPath,        /* Name of file to be deleted */
  int dirSync               /* If true, fsync() directory after deleting file */
) {
    SQLDEBUG("mirDelete: %s ERROR\n", zPath);
    /* XXX Dont have a pointer back to the sqlite_mir_file * here, so would need to 
       stored opened files somewhere. */
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
    SQLDEBUG("mirAccess: OK\n");
    *pResOut = 1;
    return SQLITE_OK;
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
    SQLDEBUG("mirFullPathname: %s OK\n", zPath);
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
    SQLDEBUG("mirRandomness: ");
    for (int i=0; i < nBuf; i++)
      zBuf[i] = rand();
    SQLDEBUG (" OK\n");
    return SQLITE_OK;
}

static int mirSleep(
  sqlite3_vfs *NotUsed, 
  int microseconds
) {
    printf("mirSleep: ERR\n");
    return SQLITE_ERROR;
}

static int mirCurrentTime(
  sqlite3_vfs *NotUsed, 
  double *prNow
) {
    printf("mirCurrentTime: ERR\n");
    return SQLITE_ERROR;
}

static int mirGetLastError(
  sqlite3_vfs *NotUsed, 
  int NotUsed2, 
  char *NotUsed3
) {
  printf("mirGetLastError: ERR\n");
  return SQLITE_ERROR;
}

struct sqlite3_vfs mirVfs = {
    1,                    /* iVersion */
    sizeof(struct sqlite3_mir_file), /* szOsFile */
    DB_NAME_MAXLENGTH,    /* mxPathname */
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

int
sqlite3_os_init(void) {
  int rc;
  rc = sqlite3_vfs_register(&mirVfs, 1);
  if (rc != SQLITE_OK)
    printf("sqlite3_os_init: ERROR\n");
  else
    printf("sqlite3_os_init: OK\n");
  return rc;
}

int
sqlite3_os_end(void) {
  printf("sqlite3_os_end: OK\n");
  return SQLITE_OK;
}

static int 
sqlite3_test_cb(void *arg, int argc, char **argv, char **col) {
  for (int i=0; i<argc; i++)
    printf("SELECT: %s = %s\n", col[i], argv[i] ? argv[i] : "NULL");
  return 0;
}

void
sqlite3_test(void) {
  sqlite3 *db;
  int ret;
  char *errmsg;
  ret = sqlite3_open("test.db", &db);
  if (ret) {
     printf("OPEN err: %s\n", sqlite3_errmsg(db));
  } else {
     printf("OPEN ok\n");
     ret = sqlite3_exec(db, "PRAGMA journal_mode=memory", NULL, NULL, &errmsg);
     if (ret) 
       printf("PRAGMA err: %s\n", sqlite3_errmsg(db));
     else
       printf("PRAGMA ok\n");
     ret = sqlite3_exec(db, "create table if not exists foo (bar1 TEXT, bar2 INTEGER)", NULL, NULL, &errmsg);
     if (ret) {
       printf("CREATE err: %s\n", sqlite3_errmsg(db));
       exit(1);
     } else
       printf("CREATE ok\n");
     ret = sqlite3_exec(db, "insert into foo VALUES(\"hello\", 1000)", NULL, NULL, &errmsg);
     if (ret) {
       printf("INSERT1 err: %s\n", sqlite3_errmsg(db));
       exit(1);
     } else
       printf("INSERT1 ok\n");
     ret = sqlite3_exec(db, "insert into foo VALUES(\"world\", 2000)", NULL, NULL, &errmsg);
     if (ret) {
       printf("INSERT2 err: %s\n", sqlite3_errmsg(db));
       exit(1);
     } else
       printf("INSERT2 ok\n");
     ret = sqlite3_exec(db, "select * from foo", sqlite3_test_cb, NULL , &errmsg);
     if (ret) {
       printf("SELECT err: %s\n", sqlite3_errmsg(db));
       exit(1);
     } else
       printf("INSERT ok\n");
     ret = sqlite3_close(db);
  }
  exit(1);
}
