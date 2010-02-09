#include "dietfeatures.h"
#include <unistd.h>
#include <md5.h>

/* Initial permutation, */
static const char IP[] = {
  57,49,41,33,25,17, 9, 1,
  59,51,43,35,27,19,11, 3,
  61,53,45,37,29,21,13, 5,
  63,55,47,39,31,23,15, 7,
  56,48,40,32,24,16, 8, 0,
  58,50,42,34,26,18,10, 2,
  60,52,44,36,28,20,12, 4,
  62,54,46,38,30,22,14, 6
};

/* Final permutation, FP = IP^(-1) */
static const char FP[] = {
  39, 7,47,15,55,23,63,31,
  38, 6,46,14,54,22,62,30,
  37, 5,45,13,53,21,61,29,
  36, 4,44,12,52,20,60,28,
  35, 3,43,11,51,19,59,27,
  34, 2,42,10,50,18,58,26,
  33, 1,41, 9,49,17,57,25,
  32, 0,40, 8,48,16,56,24
};

/* Permuted-choice 1 from the key bits to yield C and D.
 * Note that bits 8,16... are left out: They are intended for a parity check.
 */
static const char PC1_C[] = {
  56,48,40,32,24,16, 8,
   0,57,49,41,33,25,17,
   9, 1,58,50,42,34,26,
  18,10, 2,59,51,43,35
};

static const char PC1_D[] = {
  62,54,46,38,30,22,14,
   6,61,53,45,37,29,21,
  13, 5,60,52,44,36,28,
  20,12, 4,27,19,11, 3
};

/* Sequence of shifts used for the key schedule. */
static const char shifts[] = { 1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1 };

/*
 * Permuted-choice 2, to pick out the bits from the CD array that generate
 * the key schedule.
 */
static const char PC2_C[] = {
  13, 16, 10, 23,  0,  4,  2, 27, 14,  5, 20,  9,
  22, 18, 11,  3, 25,  7, 15,  6, 26, 19, 12,  1
};

static const char PC2_D[] = {
  12, 23,  2,  8, 18, 26,  1, 11, 22, 16,  4, 19,
  15, 20, 10, 27,  5, 24, 17, 13, 21,  7,  0,  3
};

/* The C and D arrays used to calculate the key schedule. */

static char C[28];
static char D[28];
/* The key schedule. Generated from the key. */
static char KS[16][48];

/* The E bit-selection table. */
static char E[48];
static const char e2[] = {
  32,  1,  2,  3,  4,  5,  4,  5,  6,  7,  8,  9,
   8,  9, 10, 11, 12, 13, 12, 13, 14, 15, 16, 17,
  16, 17, 18, 19, 20, 21, 20, 21, 22, 23, 24, 25,
  24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32,  1
};

/* Set up the key schedule from the key. */
void setkey(const char *key)
{
  register int i, j, k;
  int  t;
  int  s;

  /* First, generate C and D by permuting the key.  The low order bit of each
   * 8-bit char is not used, so C and D are only 28 bits apiece.
   */
  for(i=0; i < 28; i++) {
    C[i] = key[(int)PC1_C[i]];
    D[i] = key[(int)PC1_D[i]];
  }
  /* To generate Ki, rotate C and D according to schedule and pick up a
   * permutation using PC2.
   */
  for(i=0; i < 16; i++) {
    /* rotate. */
    s = shifts[i];
    for(k=0; k < s; k++) {
      t = C[0];
      for(j=0; j < 27; j++)
	C[j] = C[j+1];
      C[27] = t;
      t = D[0];
      for(j=0; j < 27; j++)
	D[j] = D[j+1];
      D[27] = t;
    }
    /* get Ki. Note C and D are concatenated. */
    for(j=0; j < 24; j++) {
      KS[i][j] = C[(int)PC2_C[j]];
      KS[i][j+24] = D[(int)PC2_D[j]];
    }
  }

  for(i=0; i < 48; i++)
    E[i] = e2[i];
}

/* The 8 selection functions. For some reason, they give a 0-origin index,
 * unlike everything else.
 */
static const char S[8][64] = {
  {
    14, 4,13, 1, 2,15,11, 8, 3,10, 6,12, 5, 9, 0, 7,
     0,15, 7, 4,14, 2,13, 1,10, 6,12,11, 9, 5, 3, 8,
     4, 1,14, 8,13, 6, 2,11,15,12, 9, 7, 3,10, 5, 0,
    15,12, 8, 2, 4, 9, 1, 7, 5,11, 3,14,10, 0, 6,13
  },

  {
    15, 1, 8,14, 6,11, 3, 4, 9, 7, 2,13,12, 0, 5,10,
     3,13, 4, 7,15, 2, 8,14,12, 0, 1,10, 6, 9,11, 5,
     0,14, 7,11,10, 4,13, 1, 5, 8,12, 6, 9, 3, 2,15,
    13, 8,10, 1, 3,15, 4, 2,11, 6, 7,12, 0, 5,14, 9
  },

  {
    10, 0, 9,14, 6, 3,15, 5, 1,13,12, 7,11, 4, 2, 8,
    13, 7, 0, 9, 3, 4, 6,10, 2, 8, 5,14,12,11,15, 1,
    13, 6, 4, 9, 8,15, 3, 0,11, 1, 2,12, 5,10,14, 7,
     1,10,13, 0, 6, 9, 8, 7, 4,15,14, 3,11, 5, 2,12
  },

  {
     7,13,14, 3, 0, 6, 9,10, 1, 2, 8, 5,11,12, 4,15,
    13, 8,11, 5, 6,15, 0, 3, 4, 7, 2,12, 1,10,14, 9,
    10, 6, 9, 0,12,11, 7,13,15, 1, 3,14, 5, 2, 8, 4,
     3,15, 0, 6,10, 1,13, 8, 9, 4, 5,11,12, 7, 2,14
  },

  {
     2,12, 4, 1, 7,10,11, 6, 8, 5, 3,15,13, 0,14, 9,
    14,11, 2,12, 4, 7,13, 1, 5, 0,15,10, 3, 9, 8, 6,
     4, 2, 1,11,10,13, 7, 8,15, 9,12, 5, 6, 3, 0,14,
    11, 8,12, 7, 1,14, 2,13, 6,15, 0, 9,10, 4, 5, 3
  },

  {
    12, 1,10,15, 9, 2, 6, 8, 0,13, 3, 4,14, 7, 5,11,
    10,15, 4, 2, 7,12, 9, 5, 6, 1,13,14, 0,11, 3, 8,
     9,14,15, 5, 2, 8,12, 3, 7, 0, 4,10, 1,13,11, 6,
     4, 3, 2,12, 9, 5,15,10,11,14, 1, 7, 6, 0, 8,13
  },

  {
     4,11, 2,14,15, 0, 8,13, 3,12, 9, 7, 5,10, 6, 1,
    13, 0,11, 7, 4, 9, 1,10,14, 3, 5,12, 2,15, 8, 6,
     1, 4,11,13,12, 3, 7,14,10,15, 6, 8, 0, 5, 9, 2,
     6,11,13, 8, 1, 4,10, 7, 9, 5, 0,15,14, 2, 3,12
  },

  {
    13, 2, 8, 4, 6,15,11, 1,10, 9, 3,14, 5, 0,12, 7,
     1,15,13, 8,10, 3, 7, 4,12, 5, 6,11, 0,14, 9, 2,
     7,11, 4, 1, 9,12,14, 2, 0, 6,10,13,15, 3, 5, 8,
     2, 1,14, 7, 4,10, 8,13,15,12, 9, 0, 3, 5, 6,11
  }
};

/* P is a permutation on the selected combination of the current L and key. */
static const char P[] = {
  15, 6,19,20, 28,11,27,16,  0,14,22,25,  4,17,30, 9,
   1, 7,23,13, 31,26, 2, 8, 18,12,29, 5, 21,10, 3,24
};

/* The current block, divided into 2 halves. */
static char L[64];
#define R (L+32)
static char tempL[32];
static char f[32];

/* The combination of the key and the input, before selection. */
static char preS[48];

/* The payoff: encrypt a block. */
void encrypt(char block[64],int edflag)
{
  int  i, ii;
  register int t, j, k;

  (void)edflag;
  /* First, permute the bits in the input */
  for(j=0; j < 64; j++)
    L[j] = block[(int)IP[j]];
  /* Perform an encryption operation 16 times. */
  for(ii=0; ii < 16; ii++) {
    i = ii;
    /* Save the R array, which will be the new L. */
    for(j=0; j < 32; j++)
      tempL[j] = R[j];
    /* Expand R to 48 bits using the E selector;
     * exclusive-or with the current key bits.
     */
    for(j=0; j < 48; j++)
      preS[j] = R[E[j]-1] ^ KS[i][j];
    /* The pre-select bits are now considered in 8 groups of 6 bits each.
     * The 8 selection functions map these 6-bit quantities into 4-bit
     * quantities and the results permuted to make an f(R, K).
     * The indexing into the selection functions is peculiar;
     * it could be simplified by rewriting the tables.
     */
    for(j=0; j < 8; j++) {
      t = ((j<<1)+j)<<1;
      k = S[j][(preS[t]<<5)+
	 (preS[t+1]<<3)+
	 (preS[t+2]<<2)+
	 (preS[t+3]<<1)+
	 (preS[t+4]   )+
	 (preS[t+5]<<4)];
      t = j << 2;
      f[t  ] = (k>>3)&01;
      f[t+1] = (k>>2)&01;
      f[t+2] = (k>>1)&01;
      f[t+3] = (k   )&01;
    }
    /* The new R is L ^ f(R, K). The f here has to be permuted first, though. */
    for(j=0; j < 32; j++)
      R[j] = L[j] ^ f[(int)P[j]];
    /* Finally, the new L (the original R) is copied back. */
    for(j=0; j < 32; j++)
      L[j] = tempL[j];
  }
  /* The output L and R are reversed. */
  for(j=0; j < 32; j++) {
    L[j] ^= R[j];
    R[j] ^= L[j];
    L[j] ^= R[j];
  }
  /* The final output gets the inverse permutation of the very original. */
  for(j=0; j < 64; j++)
    block[j] = L[(int)FP[j]];
}

char * crypt(const char *pw, const char *salt)
{
  register int i, j, c;
  static char block[66], iobuf[16];
#ifdef WANT_CRYPT_MD5
  if (salt[0]=='$' && salt[1]=='1' && salt[2]=='$')
    return md5crypt(pw,salt);
#endif
  for(i=0; i < 66; i++)
    block[i] = 0;
  for(i=0; (c= *pw) && i < 64; pw++) {
    for(j=0; j < 7; j++, i++)
      block[i] = (c>>(6-j)) & 01;
    i++;
  }

  setkey(block);

  for(i=0; i < 66; i++)
    block[i] = 0;

  for(i=0; i < 2; i++) {
    c = *salt++;
    iobuf[i] = c;
    if(c > 'Z')
      c -= 6;
    if(c > '9')
      c -= 7;
    c -= '.';
    for(j=0; j < 6; j++) {
      if((c>>j) & 01) {
	int ind1 = (((i<<1)+i)<< 1) + j;
	int ind2 = ind1 + 24;
	E[ind1] ^= E[ind2];
	E[ind2] ^= E[ind1];
	E[ind1] ^= E[ind2];
      }
    }
  }

  for(i=0; i < 25; i++)
    encrypt(block,0);

  for(i=0; i < 11; i++) {
    c = 0;
    for(j=0; j < 6; j++) {
      c <<= 1;
      c |= block[(((i<<1)+i)<<1)+j];
    }
    c += '.';
    if(c > '9')
      c += 7;
    if(c > 'Z')
      c += 6;
    iobuf[i+2] = c;
  }
  iobuf[i+2] = 0;
  if(iobuf[1] == 0)
    iobuf[1] = iobuf[0];
  return(iobuf);
}
