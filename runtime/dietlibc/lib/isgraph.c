int __isgraph_ascii ( int ch );
int __isgraph_ascii ( int ch ) {
  return (unsigned int)(ch - '!') < 127u - '!';
}

int isgraph ( int ch ) __attribute__((weak,alias("__isgraph_ascii")));
