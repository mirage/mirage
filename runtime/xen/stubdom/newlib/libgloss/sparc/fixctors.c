/* Code to byte-swap static constructor/destructor tables on
   broken a.out little-endian targets. The startup code should call
   __fix_ctors just before calling main.  It is safe to use on non-broken
   or big-endian targets. */

extern long __CTOR_LIST__[];
extern long __DTOR_LIST__[];

static void
byte_swap (long *entry)
{
  unsigned char *p = (unsigned char *)entry;
  unsigned char tmp;

  tmp = p[0];
  p[0] = p[3];
  p[3] = tmp;
  tmp = p[1];
  p[1] = p[2];
  p[2] = tmp;
}

static void
fix_table (long *table)
{
  long len = table[0];

  /* The heuristic for deciding if a table is broken is to examine
     the word at the start of the table, which contains the number
     of function pointers immediately following.  If the low word
     is zero, and the high word is non-zero, it's very likely that
     it is byte-swapped.  This test will fail if the program has
     an exact multiple of 64K static constructors or destructors, a very
     unlikely situation. */
  if ((len & 0xffff) == 0 && (len & 0xffff0000) != 0)
    {

      /* The table looks broken.  Byte-swap all the words in the table, up
         to a NULL entry, which marks the end of the table. */
      do
	{
	  byte_swap (table);
	  table++;
	}
      while (*table);
    }
}

void
__fix_ctors (void)
{
  fix_table (__CTOR_LIST__);
  fix_table (__DTOR_LIST__);
}
