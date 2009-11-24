
/* FIXME: can we not nuke the 10,000 copies of this function
   and fudge things (which is all this function does) in _fstat?  */
int
isatty (int fd)
{
  return 1;
}
