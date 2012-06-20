#include <time.h>

int __isleap(int year) {
  /* every fourth year is a leap year except for century years that are
   * not divisible by 400. */
/*  return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)); */
  return (!(year%4) && ((year%100) || !(year%400)));
}
