#include <stdio.h>
#include <fcntl.h>

#define USAGE	"USAGE: checkum -[vhcs] infile outfile\n\t-v\tverbose\n\
\t-h\thelp\n\t-c\tcheck checksum\n\t-s\tprint the ipl size"
static int verbose = 0;
static int verify  = 0;
static int size    = 0;

typedef int word_t;
#define WORDSIZE (sizeof(word_t))

main(argc, argv)
     int argc;
     char **argv;
{
  char	 *infile;
  char	 *outfile;
  int	 infd;
  int	 outfd;
  word_t checksum = 0;
  int	 nbytes;
  word_t buf;
  int	 i        = 1;
  int	filesize  = 0;
  
  while (*argv[i] == '-') {
      switch (*(argv[i]+1)) {
      case 'v':
	verbose++;
	break;
      case 'c':
	verify++;
	puts ("Sorry, unimplemented for now");
	exit(1);
	break;
      case 's':
	size++;
	break;
      case 'h':
	puts (USAGE);
	exit(0);
      default:
	printf ("\"%s\", Illegal option\n", argv[i]);
	puts (USAGE);
	exit(1);
    }
    i++;
  }
  infile = *(argv + i);
  outfile = *(argv + i+1);

  /* see it there were file names on the command line */
  if (infile == 0x0) {
    puts("Didn't specify an input file name");
    exit(1);
  }
  if (outfile == 0x0) {
    puts("Didn't specify an output file name");
     exit(1);
  }

  /* try to open the files */
  infd = open(infile, O_RDONLY);
  if (infd == -1) {
    printf("Couldn't open %s\n", infile);
    exit(1);
  }

  outfd = open(outfile, O_WRONLY|O_CREAT|O_TRUNC);
  if (outfd == -1) {
    printf("Couldn't open %s\n", outfile);
    exit(1);
  }

  if (verbose > 2) 
    putchar('\n');

  /* calculate the checksum */
  while ((nbytes = read(infd, &buf, WORDSIZE)) == WORDSIZE) {
    if (verbose > 2) 
      putchar('.');
    checksum+= buf;
    filesize+= WORDSIZE;
    if (write(outfd, &buf, WORDSIZE) != WORDSIZE) {
      puts("Couldn't write");
    } 
    if (verbose > 3) 
      putchar('+');
  }
  if (verbose > 2) 
    putchar('\n');
  
  /* write the last byte read */
  if (nbytes > 0) {
    write(outfd, &buf, nbytes);
    checksum+= buf;  				/* calculate the last word */
    filesize+= nbytes;
  }
  /* write the checksum */
  buf = -checksum;
  write(outfd, &buf, WORDSIZE);
  filesize+= WORDSIZE;				/* checksum increase the size */

  if (verbose > 0)
    printf("The calculated checksum is:\n\t0x%x,\n\t%u\n", -checksum, -checksum);

  /* calculate the extra 2K here */
  buf = 0;
  while ((filesize % 2048) !=0) {
    filesize+=WORDSIZE;
    write(outfd, &buf, WORDSIZE);
  }
  if (size > 0) {
    printf ("%u is the new file size\n", filesize);
  }
  close(outfd);
  close(infd);
  exit(0);
}

#if 0
/* Calculate a simple checksum and concatenate it to the end of BUF.  */
void
compute_and_concatenate_checksum (word *buf, size_t bufsize_in_words)
{
  size_t i;
  word sum;
  sum = buf[0]
  for (i = 1; i < bufsize_in_words; i++)
    sum += buf[i];
  buf[bufsize_in_words] = -sum;
}

/* Calculate a simple checksum and verify it.  NOTE: bufsize_in_words should
   include the checksum, i.e., it should be one larger than when the
   checksum was calculated using compute_and_concatenate_checksum!  */
int
compute_and_and_verify_checksum (word *buf, size_t bufsize_in_words)
{
  size_t i;
  word sum;
  sum = buf[0];
  for (i = 1; i < bufsize_in_words; i++)
    sum += buf[i];
  if (sum != 0)
    return ERROR;
  return SUCCESS;
}
#endif
