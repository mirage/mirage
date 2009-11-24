
union u {
  struct {
  short int msw;
  unsigned short lsw;
} w;
long l;
};

int
__cmpsi2(long arga,
	 short int msw_b, unsigned short int lsw_b)
{
  union u u;
  u.l = arga;

  if (u.w.msw != msw_b)
    {
      if (u.w.msw < msw_b) return 0;
      return 2;
    }
  if (u.w.lsw != lsw_b) 
    {
      if (u.w.lsw < lsw_b) return 0;
      return 2;
    }
  return 1;
}
