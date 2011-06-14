(* Bitstring library.
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
 * $Id: bitstring_types.ml 142 2008-07-17 15:45:56Z richard.wm.jones $
 *)

type endian = BigEndian | LittleEndian | NativeEndian

let string_of_endian = function
  | BigEndian -> "bigendian"
  | LittleEndian -> "littleendian"
  | NativeEndian -> "nativeendian"
