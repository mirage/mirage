/* -*-  Mode:C; c-basic-offset:4; tab-width:4 -*-
 ****************************************************************************
 * (C) 2003 - Rolf Neugebauer - Intel Research Cambridge
 ****************************************************************************
 *
 *        File: types.h
 *      Author: Rolf Neugebauer (neugebar@dcs.gla.ac.uk)
 *     Changes: 
 *              
 *        Date: May 2003
 * 
 * Environment: Xen Minimal OS
 * Description: a random collection of type definitions
 *
 ****************************************************************************
 * $Id: h-insert.h,v 1.4 2002/11/08 16:03:55 rn Exp $
 ****************************************************************************
 */

#ifndef _TYPES_H_
#define _TYPES_H_
#include <stddef.h>

/* FreeBSD compat types */
typedef long                quad_t;
typedef unsigned long       u_quad_t;

typedef struct { unsigned long pte; } pte_t;

#define __pte(x) ((pte_t) { (x) } )

#include <limits.h>
#include <stdint.h>

typedef intptr_t            ptrdiff_t;

#endif /* _TYPES_H_ */
