
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#define FILENAME   "/tmp/zz_temp_mmap_test"
#define TESTSTRING "This is a test string"


int main (int argc, char * argv[])
{
   int fd;
   void *filememory_1;
   void *filememory_2;
   
   fd = open (FILENAME, O_RDWR | O_CREAT);
   
   if (fd < 0)
   {
      fprintf (stderr, "Couldn't open %s for writing\n", FILENAME);
      return (1);
   }

   write (fd, TESTSTRING, sizeof(TESTSTRING));

   /*
      Try mmapping the newly created file...
   */

   filememory_1 = mmap (NULL, 0x0100, PROT_READ, MAP_PRIVATE, fd, 0);
   
   if (filememory_1 == (void *) -1)
   {
      perror("mmap returned error");
      return (1);
   }

   /*
      Try mmapping with a bogus file descriptor... (should fail)
   */

   filememory_2 = mmap (NULL, 0x0100, PROT_READ, MAP_PRIVATE, fd+10, 0);
   
   if ((filememory_2 != (void *) -1) || (errno != 9))
   {
      fprintf (stderr, "mmap allowed a bogus file descriptor...\n");
      return (1);
   }
   
   close (fd);

   /*
      Check that we can read back from the file OK
   */

   if ((*(unsigned char *) filememory_1) != TESTSTRING[0])
   {
      fprintf (stderr, "mmap doesn't give expected data...\n");
      return (1);
   }
   
   /*
      fixme: check unmapping as well.... ??
   */


   /*
      Clean up.
   */

   if (unlink (FILENAME) != 0)
   {
      fprintf (stderr, "Unexpected problem deleting the tempfile... ?\n");
      return (1);
   }

   return (0);
}


