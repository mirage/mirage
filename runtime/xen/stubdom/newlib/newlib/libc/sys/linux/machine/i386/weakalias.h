#define weak_alias(name, aliasname) \
  extern __typeof (name) aliasname __attribute__ ((weak, alias (#name)));

#if 0
#define weak_extern(symbol) _weak_extern (symbol)
#define _weak_extern(symbol) asm (".weak " #symbol);
#endif

#define weak_function __attribute__ ((weak))

