/*
 *  Copyright (C) 2002 by Red Hat, Incorporated. All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software
 *  is freely granted, provided that this notice is preserved.
 *
 *  Tests gleaned from Markus Kuhn's UTF-8 and Unicode FAQ,
 *  and specifically, his UTF-8-test.txt decoder stress test file.
 */

#include <stdio.h>
#include <stdlib.h>
#include <locale.h>

#define MAX_BYTES 65

int num_invalid(const char *s, int len);

char first[6][6] = {
  {0x0},                                   /* U-00000000 */
  {0xc2, 0x80},                            /* U-00000080 */
  {0xe0, 0xa0, 0x80},                      /* U-00000800 */
  {0xf0, 0x90, 0x80, 0x80},                /* U-00010000 */
  {0xf8, 0x88, 0x80, 0x80, 0x80},          /* U-00200000 */
  {0xfc, 0x84, 0x80, 0x80, 0x80, 0x80}     /* U-04000000 */
};

char last[6][6] = {
  {0x7f},                                  /* U-0000007F */
  {0xdf, 0xbf},                            /* U-000007FF */
  {0xef, 0xbf, 0xbf},                      /* U-0000FFFF */
  {0xf7, 0xbf, 0xbf, 0xbf},                /* U-001FFFFF */
  {0xfb, 0xbf, 0xbf, 0xbf, 0xbf},          /* U-03FFFFFF */
  {0xfd, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf}     /* U-7FFFFFFF */
};

char boundary[5][6] = {
  {0xed, 0x9f, 0xbf},                      /* U-0000D7FF */
  {0xee, 0x80, 0x80},                      /* U-0000E000 */
  {0xef, 0xbf, 0xbd},                      /* U-0000FFFD */
  {0xf4, 0x8f, 0xbf, 0xbf},                /* U-0010FFFF */
  {0xf4, 0x90, 0x80, 0x80}                 /* U-00110000 */
};

char continuation_bytes[8][7] = {
  {0x80},
  {0xbf},
  {0x80, 0xbf},
  {0x80, 0xbf, 0x80},
  {0x80, 0xbf, 0x80, 0xbf},
  {0x80, 0xbf, 0x80, 0xbf, 0x80},
  {0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
  {0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf, 0x80}
};

char all_continuation_bytes[64];


char all_two_byte_seq[32];
char all_three_byte_seq[16];
char all_four_byte_seq[8];
char all_five_byte_seq[4];
char all_six_byte_seq[2];

char incomplete_seq[10][6] = {
  {0xc2},                            /* U-00000080 */
  {0xe0, 0x80},                      /* U-00000800 */
  {0xf0, 0x80, 0x80},                /* U-00010000 */
  {0xf8, 0x80, 0x80, 0x80},          /* U-00200000 */
  {0xfc, 0x80, 0x80, 0x80, 0x80},    /* U-04000000 */
  {0xdf},                            /* U-000007FF */
  {0xef, 0xbf},                      /* U-0000FFFF */
  {0xf7, 0xbf, 0xbf},                /* U-001FFFFF */
  {0xfb, 0xbf, 0xbf, 0xbf},          /* U-03FFFFFF */
  {0xfd, 0xbf, 0xbf, 0xbf, 0xbf}     /* U-7FFFFFFF */
};

char incomplete_seq_concat[30];

char impossible_bytes[3][4] = {
  {0xfe},
  {0xff},
  {0xfe, 0xfe, 0xff, 0xff}
};

char overlong[5][6] = {
  {0xc0, 0xaf},
  {0xe0, 0x80, 0xaf},
  {0xf0, 0x80, 0x80, 0xaf},
  {0xf8, 0x80, 0x80, 0x80, 0xaf},
  {0xfc, 0x80, 0x80, 0x80, 0x80, 0xaf}
};

char overlong_max[5][6] = {
  {0xc1, 0xbf},
  {0xe0, 0x9f, 0xbf},
  {0xf0, 0x8f, 0xbf, 0xbf},
  {0xf8, 0x87, 0xbf, 0xbf, 0xbf},
  {0xfc, 0x83, 0xbf, 0xbf, 0xbf, 0xbf}
};

char overlong_nul[5][6] = {
  {0xc0, 0x80},
  {0xe0, 0x80, 0x80},
  {0xf0, 0x80, 0x80, 0x80},
  {0xf8, 0x80, 0x80, 0x80, 0x80},
  {0xfc, 0x80, 0x80, 0x80, 0x80, 0x80}
};

char single_surrogates[7][3] = {
  {0xed, 0xa0, 0x80},
  {0xed, 0xad, 0xbf},
  {0xed, 0xae, 0x80},
  {0xed, 0xaf, 0xbf},
  {0xed, 0xb0, 0x80},
  {0xed, 0xbe, 0x80},
  {0xed, 0xbf, 0xbf}
};

char paired_surrogates[8][6] = {
  {0xed, 0xa0, 0x80, 0xed, 0xb0, 0x80},
  {0xed, 0xa0, 0x80, 0xed, 0xbf, 0xbf},
  {0xed, 0xad, 0xbf, 0xed, 0xb0, 0x80},
  {0xed, 0xad, 0xbf, 0xed, 0xbf, 0xbf},
  {0xed, 0xae, 0x80, 0xed, 0xb0, 0x80},
  {0xed, 0xae, 0x80, 0xed, 0xbf, 0xbf},
  {0xed, 0xaf, 0xbf, 0xed, 0xb0, 0x80},
  {0xed, 0xaf, 0xbf, 0xed, 0xbf, 0xbf}
};

char illegal_pos[2][3] = {
  {0xff, 0xfe},
  {0xff, 0xff}
};
  
int main()
  {
    wchar_t wchar;
    int retval;
    int i;

    if (!setlocale(LC_CTYPE, "C-UTF-8"))
      {
        printf("Failed to set C-UTF-8 locale.\n");
        return 1;
      }
    else
      printf("Set C-UTF-8 locale.\n");

    /* 2  Boundary condition test cases */
    /* 2.1  First possible sequence of a certain length */
    retval = mbtowc(&wchar, first[0], MAX_BYTES);
    if (retval == 0)
      printf("2.1.1: U-%08d\n", wchar);
    else
      printf("2.1.1: Invalid\n");

    for (i = 2; i < 7; i++)
    {
      retval = mbtowc (&wchar, first[i-1], MAX_BYTES);
      if (retval == i)
        printf("2.1.%d: U-%08x\n", i, wchar);
      else
        printf("2.1.%d: Invalid\n", i);
    }

    /* 2.2  Last possible sequence of a certain length */
    for (i = 1; i < 7; i++)
    {
      retval = mbtowc (&wchar, last[i-1], MAX_BYTES);
      if (retval == i)
        printf("2.2.%d: U-%08x\n", i, wchar);
      else
        printf("2.2.%d: Invalid\n", i);
    }

    /* 2.3  Other boundary conditions */
    for (i = 1; i < 6; i++)
      {
        retval = mbtowc (&wchar, boundary[i-1], MAX_BYTES);
        if ((i < 4 && retval == 3) || (i > 3 && retval == 4))
          printf("2.3.%d: U-%08x\n", i, wchar);
        else
          printf("2.3.%d: Invalid\n", i);
      }

    /* 3  Malformed sequences */
    /* 3.1  Unexpected continuation bytes */
    retval = mbtowc (&wchar, continuation_bytes[0], MAX_BYTES);
    if (retval == 1)
      printf("3.1.1: U-%08x\n", wchar);
    else
      printf("3.1.1: 1 Invalid\n");

    retval = mbtowc (&wchar, continuation_bytes[1], MAX_BYTES);
    if (retval == 1)
      printf("3.1.2: U-%08x\n", wchar);
    else
      printf("3.1.2: 1 Invalid\n");

    for(i=2; i< 8; i++)
      {
        retval = num_invalid(continuation_bytes[i], i);
        if (retval == -1)
          printf("3.1.%d: Valid Character Found\n", i+1);
        else
          printf("3.1.%d: %d Invalid\n", i+1, retval);
      }

    for(i = 0x80; i < 0xc0; i++)
      all_continuation_bytes[i-0x80] = i;

    retval = num_invalid(all_continuation_bytes, 0xc0 - 0x80);
    if (retval == -1)
      printf("3.1.9: Valid Character Found\n");
    else
      printf("3.1.9: %d Invalid\n", retval);

    /* 3.2  Lonely start characters */
    for(i = 0xc0; i < 0xe0; i++)
      all_two_byte_seq[i-0xc0] = i;

    retval = num_invalid(all_two_byte_seq, 0xe0 - 0xc0);
    if (retval == -1)
      printf("3.2.1: Valid Character Found\n");
    else
      printf("3.2.1: %d Invalid\n", retval);

    for(i = 0xe0; i < 0xf0; i++)
      all_three_byte_seq[i-0xe0] = i;

    retval = num_invalid(all_three_byte_seq, 0xf0 - 0xe0);
    if (retval == -1)
      printf("3.2.2: Valid Character Found\n");
    else
      printf("3.2.2: %d Invalid\n", retval);
    
    for(i = 0xf0; i < 0xf8; i++)
      all_four_byte_seq[i-0xf0] = i;

    retval = num_invalid(all_four_byte_seq, 0xf8 - 0xf0);
    if (retval == -1)
      printf("3.2.3: Valid Character Found\n");
    else
      printf("3.2.3: %d Invalid\n", retval);
    
    for(i = 0xf8; i < 0xfc; i++)
      all_five_byte_seq[i-0xf8] = i;

    retval = num_invalid(all_five_byte_seq, 0xfc - 0xf8);
    if (retval == -1)
      printf("3.2.4: Valid Character Found\n");
    else
      printf("3.2.4: %d Invalid\n", retval);

    for(i = 0xfc; i < 0xfe; i++)
      all_six_byte_seq[i-0xfc] = i;

    retval = num_invalid(all_six_byte_seq, 0xfe - 0xfc);
    if (retval == -1)
      printf("3.2.5: Valid Character Found\n");
    else
      printf("3.2.5: %d Invalid\n", retval);

    /* 3.3  Sequences with last continuation byte missing */
    for(i = 1; i < 6; i++)
      {
        retval = mbtowc(&wchar, incomplete_seq[i-1], i);
        if(retval == -1)
          printf("3.3.%d: 1 Invalid\n", i);
        else
          printf("3.3.%d: Valid Character Found\n", i);
      }

    for(i = 6; i < 11; i++)
      {
        retval = mbtowc(&wchar, incomplete_seq[i-1], i - 5);
        if(retval == -1)
          printf("3.3.%d: 1 Invalid\n", i);
        else
          printf("3.3.%d: Valid Character Found\n", i);
      }

    /* 3.4  Concatenation of incomplete sequences */
    /* This test is excluded because the mbtowc function does not return the
       number of bytes read in an invalid multi-byte sequence. */

    /* 3.5  Impossible bytes */
    retval = mbtowc(&wchar, impossible_bytes[0], 1);
    if(retval == -1)
      printf("3.5.1: 1 Invalid\n");
    else
      printf("3.5.1: Valid Character Found\n");

    retval = mbtowc(&wchar, impossible_bytes[1], 1);
    if(retval == -1)
      printf("3.5.2: 1 Invalid\n");
    else
      printf("3.5.2: Valid Character Found\n");

    retval = mbtowc(&wchar, impossible_bytes[2], 4);
    if(retval == -1)
      printf("3.5.3: 1 Invalid\n");
    else
      printf("3.5.3: Valid Character Found\n");

    /* 4  Overlong sequences */
    /* 4.1  Examples of an overlong ASCII character */
    for(i = 2; i < 7; i++)
      {
        retval = mbtowc(&wchar, overlong[i-2], i);
        if(retval == -1)
          printf("4.1.%d: 1 Invalid\n", i-1);
        else
          printf("4.1.%d: Valid Character Found\n", i-1);
      }

    /* 4.2  Maximum overlong sequences */
    for(i = 2; i < 7; i++)
      {
        retval = mbtowc(&wchar, overlong_max[i-2], i);
        if(retval == -1)
          printf("4.2.%d: 1 Invalid\n", i-1);
        else
          printf("4.2.%d: Valid Character Found\n", i-1);
      }

    /* 4.3  Overlong representation of the NUL character */
    for(i = 2; i < 7; i++)
      {
        retval = mbtowc(&wchar, overlong_nul[i-2], i);
        if(retval == -1)
          printf("4.3.%d: 1 Invalid\n", i-1);
        else
          printf("4.3.%d: Valid Character Found\n", i-1);
      }

    /* 5  Illegal code positions */
    /* 5.1 Single UTF-16 surrogates */
    for (i = 1; i < 8; i++)
      {
        retval = mbtowc(&wchar, single_surrogates[i-1], 3);
        if(retval == -1)
          printf("5.1.%d: 1 Invalid\n", i);
        else
          printf("5.1.%d: Valid Character Found\n", i);
      }
    
    /* 5.2 Paired UTF-16 surrogates */
    for (i = 1; i < 8; i++)
      {
        retval = mbtowc(&wchar, paired_surrogates[i-1], 6);
        if(retval == -1)
          printf("5.2.%d: 1 Invalid\n", i);
        else
          printf("5.2.%d: Valid Character Found\n", i);
      }

    /* 5.3 Other illegal code positions */
    retval = mbtowc(&wchar, illegal_pos[0], 3);
    if(retval == -1)
      printf("5.3.1: 1 Invalid\n");
    else
      printf("5.3.1: Valid Character Found\n");

    retval = mbtowc(&wchar, illegal_pos[1], 3);
    if(retval == -1)
      printf("5.3.2: 1 Invalid\n");
    else
      printf("5.3.2: Valid Character Found\n");
    
    return 0;
  }

/* return number of invalid characters in string,
   returns -1 if a valid character is found */
int
num_invalid(const char *s, int len)
{
  int retval = 0;
  int i = 0;
  int num_inv = 0;
  wchar_t wchar;
  const char *t;

  t = s;

  for(i=0; i<len; t++, i++)
    {
      retval = mbtowc (&wchar, t, len - i);
      if(retval == -1)
        num_inv++;
      else
        return -1;
    }
  return num_inv;
}
