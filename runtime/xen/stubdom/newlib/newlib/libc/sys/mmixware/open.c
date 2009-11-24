/* open for MMIXware.

   Copyright (C) 2001, 2002 Hans-Peter Nilsson

   Permission to use, copy, modify, and distribute this software is
   freely granted, provided that the above copyright notice, this notice
   and the following disclaimer are preserved with no changes.

   THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.  */

#include <stdlib.h>
#include <fcntl.h>
#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"
#include <errno.h>

/* Let's keep the filehandle array here, since this is a primary
   initializer of it.  */
unsigned char _MMIX_allocated_filehandle[32] =
 {
   1,
   1,
   1,
   0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0
 };

int
_open (const char *path,
       int flags, ...)
{
  long fileno;
  unsigned char mode;
  long append_contents = 0;
  unsigned long prev_contents_size = 0;
  char *prev_contents = NULL;
  long ret;

  for (fileno = 0;
       fileno < (sizeof (_MMIX_allocated_filehandle) /
		 sizeof (_MMIX_allocated_filehandle[0]));
       fileno++)
    if (_MMIX_allocated_filehandle[fileno] == 0)
      break;

  if (fileno == (sizeof (_MMIX_allocated_filehandle) /
		 sizeof (_MMIX_allocated_filehandle[0])))
    {
      errno = EMFILE;
      return -1;
    }

  /* We map this to a fopen call.  The flags parameter is stymied because
     we don't support other than these flags.  */
  if (flags & ~(O_RDONLY | O_WRONLY | O_RDWR | O_CREAT | O_APPEND | O_TRUNC))
    {
      UNIMPLEMENTED (("path: %s, flags: %d", path, flags));
      errno = ENOSYS;
      return -1;
    }

  if ((flags & O_ACCMODE) == O_RDONLY)
    mode = BinaryRead;
  else if ((flags & (O_WRONLY | O_APPEND)) == (O_WRONLY | O_APPEND))
    {
      mode = BinaryReadWrite;
      append_contents = 1;
    }
  else if ((flags & (O_RDWR | O_APPEND)) == (O_RDWR | O_APPEND))
    {
      mode = BinaryReadWrite;
      append_contents = 1;
    }
  else if ((flags & (O_WRONLY | O_CREAT)) == (O_WRONLY | O_CREAT)
	   || (flags & (O_WRONLY | O_TRUNC)) == (O_WRONLY | O_TRUNC))
    mode = BinaryWrite;
  else if ((flags & (O_RDWR | O_CREAT)) == (O_RDWR | O_CREAT))
    mode = BinaryReadWrite;
  else if (flags & O_RDWR)
    mode = BinaryReadWrite;
  else
    {
      errno = EINVAL;
      return -1;
    }

  if (append_contents)
    {
      /* BinaryReadWrite is equal to "w+", so it truncates the file rather
	 than keeping the contents, as can be imagined if you're looking
	 for append functionality.  The only way we can keep the contents
	 so we can append to it, is by first reading in and saving the
	 contents, then re-opening the file as BinaryReadWrite and write
	 the previous contents.  This seems to work for the needs of
	 simple test-programs.  */
      long openexist = TRAP3f (SYS_Fopen, fileno, path, BinaryRead);
      if (openexist == 0)
	{
	  /* Yes, this file exists, now opened, so let's read it and keep
             the contents.  Better have the memory around for this to
             work.  */
	  long seekval = TRAP2f (SYS_Fseek, fileno, -1);

	  if (seekval == 0)
	    {
	      prev_contents_size = TRAP1f (SYS_Ftell, fileno);

	      /* If the file has non-zero size, we have something to
		 append to.  */
	      if (prev_contents_size != 0)
		{
		  /* Start reading from the beginning.  Ignore the return
		     value from this call: we'll notice if we can't read
		     as much as we want.  */
		  TRAP2f (SYS_Fseek, fileno, 0);

		  prev_contents = malloc (prev_contents_size);
		  if (prev_contents != 0)
		    {
		      /* I don't like the thought of trying to read the
			 whole file all at once, disregarding the size,
			 because the host system might not support that
			 and we'd get funky errors.  Read in 32k at a
			 time.  */
		      char *ptr = prev_contents;
		      unsigned long read_more = prev_contents_size;
		      unsigned long chunk_size = 1 << 15;

		      while (read_more >= chunk_size)
			{
			  long readval
			    = TRAP3f (SYS_Fread, fileno, ptr, chunk_size);

			  if (readval != 0)
			    {
			      free (prev_contents);
			      TRAP1f (SYS_Fclose, fileno);
			      errno = EIO;
			      return -1;
			    }
			  read_more -= chunk_size;
			  ptr += chunk_size;
			}

		      if (read_more != 0)
			{
			  long readval
			    = TRAP3f (SYS_Fread, fileno, ptr, read_more);
			  if (readval != 0)
			    {
			      free (prev_contents);
			      TRAP1f (SYS_Fclose, fileno);
			      errno = EIO;
			      return -1;
			    }
			}
		    }
		  else
		    {
		      /* Malloc of area to copy to failed.  The glibc
			 manpage says its open can return ENOMEM due to
			 kernel memory failures, so let's do that too
			 here.  */
		      errno = ENOMEM;
		      return -1;
		    }
		}
	    }
	  else
	    {
	      /* Seek failed.  Gotta be some I/O error.  */
	      errno = EIO;
	      return -1;
	    }

	  TRAP1f (SYS_Fclose, fileno);
	}
    }

  ret = TRAP3f (SYS_Fopen, fileno, path, mode);
  if (ret < 0)
    {
      /* It's totally unknown what the error was.  We'll just take our
	 chances and assume ENOENT.  */
      errno = ENOENT;
      return -1;
    }

  if (prev_contents_size != 0)
    {
      /* Write out the previous contents, a chunk at a time.  Leave the
	 file pointer at the end of the file.  */
      unsigned long write_more = prev_contents_size;
      unsigned long chunk_size = 1 << 15;
      char *ptr = prev_contents;

      while (write_more >= chunk_size)
	{
	  long writeval
	    = TRAP3f (SYS_Fwrite, fileno, ptr, chunk_size);
	  if (writeval != 0)
	    {
	      free (prev_contents);
	      TRAP1f (SYS_Fclose, fileno);
	      errno = EIO;
	      return -1;
	    }
	  write_more -= chunk_size;
	  ptr += chunk_size;
	}
      if (write_more != 0)
	{
	  long writeval
	    = TRAP3f (SYS_Fwrite, fileno, ptr, write_more);
	  if (writeval != 0)
	    {
	      free (prev_contents);
	      TRAP1f (SYS_Fclose, fileno);
	      errno = EIO;
	      return -1;
	    }
	}

      free (prev_contents);
    }

  _MMIX_allocated_filehandle[fileno] = 1;

  return fileno;
}
