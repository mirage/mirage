static unsigned long _dl_div(
	unsigned long num,
	unsigned long den,
	unsigned long * rem)
{
  unsigned long quot = 0, qbit = 1;

  if (den == 0)
    return 0;
  /* Left-justify denominator and count shift */
  while ((int) den >= 0) {
    den <<= 1;
    qbit <<= 1;
  }
  while (qbit) {
    if (den <= num) {
      num -= den;
      quot += qbit;
    }
    den >>= 1;
    qbit >>= 1;
  }
  if (rem)
    *rem = num;
  return quot;
}

static unsigned long _dl_mod(unsigned long num, unsigned long den)
{
  unsigned long rem;
  _dl_div(num, den, &rem);
  return rem;
}
