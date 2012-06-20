
#include <stdio.h>
#include <string.h>

#ifndef __dietlibc__
#warning "You are not using diet libc, md5 test disbled"
int main(void) { return 0; }
#else
#include <md5.h>


#if defined (__i386__) || defined (__x86_64__)
 #define RDTSC(dst) { asm volatile ("rdtsc" : "=a" (dst) : : "edx"); }
 #define ITERATIONS 10
#else
 #define RDTSC(dst) { dst = 0; }
 #define ITERATIONS 1
#endif


static const char rawdata[] = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "bcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "cdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "defghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "efghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "fghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "ghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "hijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "ijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "jklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "klmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "lmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "mnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "nopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "opqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "pqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "qrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "rstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "stuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "tuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "uvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "vwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "wxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789"
                              "xyz0123456789abcdefghijklmnopqrstuvwxyz0123456789";


/*
   You will just have to trust me that this is correct... :-)
*/

static const char hash_expected[32+1] = "45392e1d034f05172294e7714c555fac";


static int IsLittleEndian (void)
{
   static const unsigned long ul = 0x00000001;

   return ((int) (*((unsigned char *) &ul)));
}

static int IsBigEndian (void)
{
   static const unsigned long ul = 0x01000000;

   return ((int) (*((unsigned char *) &ul)));
}


int main (int argc, char *argv[])
{
   int i, j;
   int errorcode = 0;

   unsigned int start;
   unsigned int stop;
   unsigned int fastest;
   
   unsigned int total_hashed_byte_count;
   unsigned int total_md5update_calls;

   MD5_CTX Context;

   unsigned char hash[16];

   char hash_as_ascii[32+1];

   char *result;

   if (IsLittleEndian() && !IsBigEndian())
   {
      printf ("\n\nThis platform is Little-Endian\n");
   }
	else if (!IsLittleEndian() && IsBigEndian())
   {
      printf ("\n\nThis platform is Big-Endian\n");
   }
	else
   {
      printf ("\n\nThis platform is Broken.\n");
   }

   fastest = 0xffffffff;

   for (i = 0; i < ITERATIONS; i++)
   {
      total_hashed_byte_count = 0;
      total_md5update_calls = 0;

      RDTSC(start);

      MD5Init (&Context);

      for (j = 0; j < sizeof(rawdata); j++)
      {
         unsigned int hashed_byte_count = (sizeof(rawdata) - j);

         MD5Update (&Context, (unsigned char *) &rawdata[j], hashed_byte_count);

         total_hashed_byte_count += hashed_byte_count;
         total_md5update_calls++;
      }

      MD5Final (hash, &Context);
   
      RDTSC(stop);
      
      fastest = ((stop - start) < fastest) ? (stop - start) : fastest;
   }      

   sprintf (hash_as_ascii, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            hash[ 0], hash[ 1], hash[ 2], hash[ 3], hash[ 4], hash[ 5], hash[ 6], hash[ 7],
            hash[ 8], hash[ 9], hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]);

   if (strcmp (hash_expected, hash_as_ascii) == 0)
   {
      result = " (Passed)";
   }
   else
   {
      result = " (Failed !!)";
      errorcode++;
   }
   
   printf ("\n");
   printf ("MD5 Hashing test (aligned + unaligned data)\n");
   printf ("-------------------------------------------\n");
   printf ("Expected Hash      = %s\n",   hash_expected);
   printf ("Actual Hash        = %s%s\n", hash_as_ascii, result);
   printf ("Execution time     = %d\n",   fastest);
   printf ("Hashed bytes       = %d\n",   total_hashed_byte_count);     /* NB: total is per iteration */
   printf ("Calls to MD5Update = %d\n",   total_md5update_calls);       /* NB: total is per iteration */
   
   printf ("\n");

   return (errorcode);
}
#endif

