#include <assert.h>
#include <stdio.h>
#include <mntent.h>

int main() {
 int entsuccess=0;
 FILE* fstab = setmntent("fstab", "r");
 struct mntent* e;

 if (!fstab) {
     perror("setmntent()");
     return 1;
 }

while ((e = getmntent(fstab))) {
 entsuccess=1;
#if 0
  char    *mnt_fsname;    /* name of mounted file system */
  char    *mnt_dir;       /* file system path prefix */
  char    *mnt_type;      /* mount type (see mntent.h) */
  char    *mnt_opts;      /* mount options (see mntent.h) */
  int     mnt_freq;       /* dump frequency in days */
  int     mnt_passno;     /* pass number on parallel fsck */
#endif
 printf("fsname %s\n  dir %s\n  type %s\n  opts %s\n  freq %d\n  passno %d\n\n",
      e->mnt_fsname,e->mnt_dir,e->mnt_type,e->mnt_opts,e->mnt_freq,e->mnt_passno);
 }

 if ( !entsuccess ) {
   perror("getmntent()");
   return 2;
 }

 printf("closing /etc/fstab\n");
 assert ( 1 == endmntent(fstab));
 printf("closing /etc/fstab again\n");
 assert ( 1 == endmntent(fstab)); /* endmntent must always return 1 */
 printf("entmntent(0)\n");
 assert ( 1 == endmntent(0)); /* causes a segfault with diet libc */
 return 0;
}

