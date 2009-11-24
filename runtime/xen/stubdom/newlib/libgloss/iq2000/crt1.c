

/* This object reserves enough space for an EH frame initialization
object.  */

struct object {
  void *reserve[7];
};


void _main ()
{
  static int initialized;
  static struct object object;
  if (! initialized)
    {
      typedef void (*pfunc) ();
      extern pfunc __ctors[];
      extern pfunc __ctors_end[];
      extern unsigned char __eh_frame_begin[];
      extern void __register_frame_info (void *, struct object *);

      pfunc *p;

      initialized = 1;
      for (p = __ctors_end; p > __ctors; )
	(*--p) ();

      __register_frame_info (__eh_frame_begin, &object);
    }
}
