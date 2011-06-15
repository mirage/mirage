/* Bitstring library.
 * Copyright (C) 2008 Red Hat Inc., Richard W.M. Jones
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version,
 * with the OCaml linking exception described in COPYING.LIB.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * $Id: bitstring.ml 146 2008-08-20 16:58:33Z richard.wm.jones $
 */

/* This file contains hand-coded, optimized C implementations of
 * certain very frequently used functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <byteswap.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>

/* Fastpath functions.  These are used in the common case for reading
 * ints where the following conditions are known to be true:
 * (a) the int size is a whole number of bytes (eg. 16, 24, 32, etc bits)
 * (b) the access in the match is byte-aligned
 * (c) the access in the underlying bitstring is byte-aligned
 *
 * These functions are all "noalloc" meaning they must not perform
 * any OCaml allocations.  For this reason, when the function returns
 * an int32 or int64, the OCaml code passes in the pre-allocated pointer
 * to the return value.
 *
 * The final offset in the string is calculated by the OCaml (caller)
 * code.  All we need to do is to read the string+offset and byteswap,
 * sign-extend as necessary.
 *
 * There is one function for every combination of:
 * (i) int size: 16, 32, 64 bits
 * (ii) endian: bigendian, littleendian, nativeendian
 * (iii) signed and unsigned
 *
 * XXX Future work: Expand this to 24, 40, 48, 56 bits.  This
 * requires some extra work because sign-extension won't "just happen".
 */

#ifdef WORDS_BIGENDIAN
#define swap_be(size,v)
#define swap_le(size,v) v = bswap_##size (v)
#define swap_ne(size,v)
#else
#define swap_be(size,v) v = bswap_##size (v)
#define swap_le(size,v)
#define swap_ne(size,v)
#endif

#define fastpath1(size,endian,signed,type)				\
  CAMLprim value							\
  ocaml_bitstring_extract_fastpath_int##size##_##endian##_##signed	\
  (value strv, value offv)						\
  {									\
    type *ptr = (type *) ((void *) String_val (strv) + Int_val (offv));	\
    type r;								\
    r = *ptr;								\
    swap_##endian(size,r);						\
    return Val_int (r);							\
  }

fastpath1(16,be,unsigned,uint16_t)
fastpath1(16,le,unsigned,uint16_t)
fastpath1(16,ne,unsigned,uint16_t)
fastpath1(16,be,signed,int16_t)
fastpath1(16,le,signed,int16_t)
fastpath1(16,ne,signed,int16_t)

#define fastpath2(size,endian,signed,type,rval)				\
  CAMLprim value							\
  ocaml_bitstring_extract_fastpath_int##size##_##endian##_##signed	\
  (value strv, value offv, value rv)					\
  {									\
    type *ptr = (type *) ((void *) String_val (strv) + Int_val (offv));	\
    type r;								\
    r = *ptr;								\
    swap_##endian(size,r);						\
    rval(rv) = r;							\
    return rv;								\
  }

fastpath2(32,be,unsigned,uint32_t,Int32_val)
fastpath2(32,le,unsigned,uint32_t,Int32_val)
fastpath2(32,ne,unsigned,uint32_t,Int32_val)
fastpath2(32,be,signed,int32_t,Int32_val)
fastpath2(32,le,signed,int32_t,Int32_val)
fastpath2(32,ne,signed,int32_t,Int32_val)

/* Special care needs to be taken on ARCH_ALIGN_INT64 platforms
   (hppa and sparc in Debian). */

#ifdef ARCH_ALIGN_INT64
#include <caml/memory.h>
#include <caml/alloc.h>
#define fastpath3(size,endian,signed,type,rval)				\
  CAMLprim value							\
  ocaml_bitstring_extract_fastpath_int##size##_##endian##_##signed	\
  (value strv, value offv, value rv)					\
  {									\
    CAMLparam3(strv, offv, rv);						\
    type *ptr = (type *) ((void *) String_val (strv) + Int_val (offv));	\
    type r;								\
    r = *ptr;								\
    swap_##endian(size,r);						\
    CAMLreturn(caml_copy_int64(r));					\
  }

#else
#define fastpath3 fastpath2
#endif

fastpath3(64,be,unsigned,uint64_t,Int64_val)
fastpath3(64,le,unsigned,uint64_t,Int64_val)
fastpath3(64,ne,unsigned,uint64_t,Int64_val)
fastpath3(64,be,signed,int64_t,Int64_val)
fastpath3(64,le,signed,int64_t,Int64_val)
fastpath3(64,ne,signed,int64_t,Int64_val)
