

short 
__mulhi3(short a, short b)
{
  int r;

  r = 0;
  while (a) 
    {
      if (a & 1) 
	{
	  r += b;
	  a>>=1;
	  b<<=1;
	}
    }
  return r;
}


