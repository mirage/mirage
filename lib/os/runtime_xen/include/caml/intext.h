/***********************************************************************/
/*                                                                     */
/*                           Objective Caml                            */
/*                                                                     */
/*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         */
/*                                                                     */
/*  Copyright 1996 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../LICENSE.     */
/*                                                                     */
/***********************************************************************/

/* $Id: intext.h,v 1.32 2005/09/22 14:21:50 xleroy Exp $ */

/* Structured input/output */

#ifndef CAML_INTEXT_H
#define CAML_INTEXT_H

#ifndef CAML_NAME_SPACE
#include "compatibility.h"
#endif
#include "misc.h"
#include "mlvalues.h"


CAMLextern void caml_output_value_to_malloc(value v, value flags,
                                            /*out*/ char ** buf,
                                            /*out*/ intnat * len);
  /* Output [v] with flags [flags] to a memory buffer allocated with
     malloc.  On return, [*buf] points to the buffer and [*len]
     contains the number of bytes in buffer. */
CAMLextern intnat caml_output_value_to_block(value v, value flags,
                                             char * data, intnat len);
  /* Output [v] with flags [flags] to a user-provided memory buffer.
     [data] points to the start of this buffer, and [len] is its size
     in bytes.  Return the number of bytes actually written in buffer.
     Raise [Failure] if buffer is too short. */


CAMLextern value caml_input_val_from_string (value str, intnat ofs);
  /* Read a structured value from the Caml string [str], starting
     at offset [ofs]. */
CAMLextern value caml_input_value_from_malloc(char * data, intnat ofs);
  /* Read a structured value from a malloced buffer.  [data] points
     to the beginning of the buffer, and [ofs] is the offset of the
     beginning of the externed data in this buffer.  The buffer is
     deallocated with [free] on return, or if an exception is raised. */
CAMLextern value caml_input_value_from_block(char * data, intnat len);
  /* Read a structured value from a user-provided buffer.  [data] points
     to the beginning of the externed data in this buffer,
     and [len] is the length in bytes of valid data in this buffer.
     The buffer is never deallocated by this routine. */

/* Functions for writing user-defined marshallers */

CAMLextern void caml_serialize_int_1(int i);
CAMLextern void caml_serialize_int_2(int i);
CAMLextern void caml_serialize_int_4(int32 i);
CAMLextern void caml_serialize_int_8(int64 i);
CAMLextern void caml_serialize_float_4(float f);
CAMLextern void caml_serialize_float_8(double f);
CAMLextern void caml_serialize_block_1(void * data, intnat len);
CAMLextern void caml_serialize_block_2(void * data, intnat len);
CAMLextern void caml_serialize_block_4(void * data, intnat len);
CAMLextern void caml_serialize_block_8(void * data, intnat len);
CAMLextern void caml_serialize_block_float_8(void * data, intnat len);

CAMLextern int caml_deserialize_uint_1(void);
CAMLextern int caml_deserialize_sint_1(void);
CAMLextern int caml_deserialize_uint_2(void);
CAMLextern int caml_deserialize_sint_2(void);
CAMLextern uint32 caml_deserialize_uint_4(void);
CAMLextern int32 caml_deserialize_sint_4(void);
CAMLextern uint64 caml_deserialize_uint_8(void);
CAMLextern int64 caml_deserialize_sint_8(void);
CAMLextern float caml_deserialize_float_4(void);
CAMLextern double caml_deserialize_float_8(void);
CAMLextern void caml_deserialize_block_1(void * data, intnat len);
CAMLextern void caml_deserialize_block_2(void * data, intnat len);
CAMLextern void caml_deserialize_block_4(void * data, intnat len);
CAMLextern void caml_deserialize_block_8(void * data, intnat len);
CAMLextern void caml_deserialize_block_float_8(void * data, intnat len);
CAMLextern void caml_deserialize_error(char * msg);


#endif /* CAML_INTEXT_H */
