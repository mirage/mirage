
#include <math.h>
#include "dietlibm.h"

double  pow ( double mant, double expo )
{
    unsigned int  e;
    long double   ret;

    /* special cases 0^x */
    if ( mant == 0. ) {
        if ( expo > 0. )
            return 0.;
        else if ( expo == 0. )
            return 1.;
        else
            return 1./mant;
    }
    
    /* special cases x^n with n is integer */
    if ( expo == (int) (e = (int) expo) ) {
           
        if ( (int)e < 0 ) {
            e    = -e;
            mant = 1./mant;
        }
   
        ret = 1.;
        
        while (1) {
            if ( e & 1 )
                ret *= mant;
            if ( (e >>= 1) == 0 )
                break;
            mant *= mant;
         }
        return ret;
    }
    
    /* normal case */
    return exp ( log (mant) * expo );
}
