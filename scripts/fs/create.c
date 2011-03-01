/*
 * Copyright (c) 2011 Julian Chesterfield <julian.chesterfield@citrix.com>
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


#include "mirage-fs.h"

void usage() {
  printf("Usage:\n\tcreate <Dir> <OUTPUT>\n");
}

int main(int argc, char *argv[]) {
  struct dirent* dirp;
  DIR* d;
  char *dir, *path;
  int outfd, infd;
  struct stat st;
  struct fs_hdr *fsh;
  int fseek = START_OFFSET;
  int mseek = 0;
  int size;

  if (argc != 3) {
    usage();
    return -1;
  } 

  outfd = open(argv[2],O_WRONLY);
  if (outfd == -1 && errno == ENOENT) {
    outfd = open(argv[2],O_CREAT|O_WRONLY);
  }
  if (outfd == -1) {
    printf("Failed to open output file\n");
    return -1;
  }

  //Zero out metadata region and reset filehandle
  fzero(outfd, START_OFFSET);
  lseek(outfd,mseek,SEEK_SET);
  

  dir = strdup(argv[1]);
  if ((d = opendir(argv[1])) == NULL) {
    return -1;
  }

  while ((dirp = readdir(d)) != NULL) {
    if (dirp->d_type == DT_REG) {
      printf("%s/%s\n", dir, dirp->d_name);
      size = strlen(dir) + strlen(dirp->d_name) + 2;
      path = malloc(size);
      if(!path) {
	printf("Failed to malloc %d bytes\n",size);
	continue;
      }
      snprintf(path,size,"%s/%s", dir, dirp->d_name);

      //Open the file and write to dst
      infd = open(path, O_RDONLY);
      free(path);

      if(fstat(infd, &st)!=0) {
	printf("Failed to stat input file, continuing...\n");
	continue;
      }

      lseek(outfd, fseek,SEEK_SET);
      size = fcopy(infd,outfd,roundup(st.st_size,SECTOR_SIZE));
      if (size < st.st_size)
	printf("Short file write [%s,%lu,%d]\n",dirp->d_name,st.st_size,size);
      close(infd);

      //Seek to location and Write FS metadata
      fsh = init_hdr(dirp->d_name, st.st_size, fseek);
      lseek(outfd,mseek,SEEK_SET);
      write(outfd, fsh, sizeof(struct fs_hdr));

      printf("Wrote Node: %s, size: %llu, offset: %llu\n",
	     fsh->filename, fsh->length, fsh->offset);

      //Reset FD pointers
      mseek += SECTOR_SIZE;
      fseek += roundup(size,PAGE_SIZE);

      free(fsh);
      close(infd);
    }
  }
  lseek(outfd,fseek,SEEK_SET);
  close(outfd);
  closedir(d);
  return 0;
}
