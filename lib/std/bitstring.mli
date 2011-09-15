(** Bitstring library. *)
(* Copyright (C) 2008 Red Hat Inc., Richard W.M. Jones
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
 * $Id: bitstring.mli 159 2008-08-27 11:26:45Z richard.wm.jones $
 *)

(**
   {{:#reference}Jump straight to the reference section for
   documentation on types and functions}.

   {2 Introduction}

   Bitstring adds Erlang-style bitstrings and matching over bitstrings
   as a syntax extension and library for OCaml.  You can use
   this module to both parse and generate binary formats, for
   example, communications protocols, disk formats and binary files.

   {{:http://code.google.com/p/bitstring/}OCaml bitstring website}

   This library used to be called "bitmatch".

   {2 Examples}

   A function which can parse IPv4 packets:

{[
let display pkt =
  bitmatch pkt with
  (* IPv4 packet header
    0                   1                   2                   3   
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   4   |  IHL  |Type of Service|          Total Length         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Identification        |Flags|      Fragment Offset    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Time to Live |    Protocol   |         Header Checksum       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                       Source Address                          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Destination Address                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Options                    |    Padding    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  *)
  | { 4 : 4; hdrlen : 4; tos : 8;   length : 16;
      identification : 16;          flags : 3; fragoffset : 13;
      ttl : 8; protocol : 8;        checksum : 16;
      source : 32;
      dest : 32;
      options : (hdrlen-5)*32 : bitstring;
      payload : -1 : bitstring } ->

    printf "IPv4:\n";
    printf "  header length: %d * 32 bit words\n" hdrlen;
    printf "  type of service: %d\n" tos;
    printf "  packet length: %d bytes\n" length;
    printf "  identification: %d\n" identification;
    printf "  flags: %d\n" flags;
    printf "  fragment offset: %d\n" fragoffset;
    printf "  ttl: %d\n" ttl;
    printf "  protocol: %d\n" protocol;
    printf "  checksum: %d\n" checksum;
    printf "  source: %lx  dest: %lx\n" source dest;
    printf "  header options + padding:\n";
    Bitstring.hexdump_bitstring stdout options;
    printf "  packet payload:\n";
    Bitstring.hexdump_bitstring stdout payload

  | { version : 4 } ->
    eprintf "unknown IP version %d\n" version;
    exit 1

  | { _ } as pkt ->
    eprintf "data is smaller than one nibble:\n";
    Bitstring.hexdump_bitstring stderr pkt;
    exit 1
]}

   A program which can parse
   {{:http://lxr.linux.no/linux/include/linux/ext3_fs.h}Linux EXT3 filesystem superblocks}:

{[
let bits = Bitstring.bitstring_of_file "tests/ext3_sb"

let () =
  bitmatch bits with
  | { s_inodes_count : 32 : littleendian;       (* Inodes count *)
      s_blocks_count : 32 : littleendian;       (* Blocks count *)
      s_r_blocks_count : 32 : littleendian;     (* Reserved blocks count *)
      s_free_blocks_count : 32 : littleendian;  (* Free blocks count *)
      s_free_inodes_count : 32 : littleendian;  (* Free inodes count *)
      s_first_data_block : 32 : littleendian;   (* First Data Block *)
      s_log_block_size : 32 : littleendian;     (* Block size *)
      s_log_frag_size : 32 : littleendian;      (* Fragment size *)
      s_blocks_per_group : 32 : littleendian;   (* # Blocks per group *)
      s_frags_per_group : 32 : littleendian;    (* # Fragments per group *)
      s_inodes_per_group : 32 : littleendian;   (* # Inodes per group *)
      s_mtime : 32 : littleendian;              (* Mount time *)
      s_wtime : 32 : littleendian;              (* Write time *)
      s_mnt_count : 16 : littleendian;          (* Mount count *)
      s_max_mnt_count : 16 : littleendian;      (* Maximal mount count *)
      0xef53 : 16 : littleendian } ->           (* Magic signature *)

    printf "ext3 superblock:\n";
    printf "  s_inodes_count = %ld\n" s_inodes_count;
    printf "  s_blocks_count = %ld\n" s_blocks_count;
    printf "  s_free_inodes_count = %ld\n" s_free_inodes_count;
    printf "  s_free_blocks_count = %ld\n" s_free_blocks_count

  | { _ } ->
    eprintf "not an ext3 superblock!\n%!";
    exit 2
]}

   Constructing packets for a simple binary message
   protocol:

{[
(*
  +---------------+---------------+--------------------------+
  | type          | subtype       | parameter                |
  +---------------+---------------+--------------------------+
   <-- 16 bits --> <-- 16 bits --> <------- 32 bits -------->

  All fields are in network byte order.
*)

let make_message typ subtype param =
  (BITSTRING {
     typ : 16;
     subtype : 16;
     param : 32
   }) ;;
]}

   {2 Loading, creating bitstrings}

   The basic data type is the {!bitstring}, a string of bits of
   arbitrary length.  Bitstrings can be any length in bits and
   operations do not need to be byte-aligned (although they will
   generally be more efficient if they are byte-aligned).

   Internally a bitstring is stored as a normal OCaml [string]
   together with an offset and length, where the offset and length are
   measured in bits.  Thus one can efficiently form substrings of
   bitstrings, overlay a bitstring on existing data, and load and save
   bitstrings from files or other external sources.

   To load a bitstring from a file use {!bitstring_of_file} or
   {!bitstring_of_chan}.

   There are also functions to create bitstrings from arbitrary data.
   See the {{:#reference}reference} below.

   {2 Matching bitstrings with patterns}

   Use the [bitmatch] operator (part of the syntax extension) to break
   apart a bitstring into its fields.  [bitmatch] works a lot like the
   OCaml [match] operator.

   The general form of [bitmatch] is:

   [bitmatch] {i bitstring-expression} [with]

   [| {] {i pattern} [} ->] {i code}

   [| {] {i pattern} [} ->] {i code}

   [|] ...

   As with normal match, the statement attempts to match the
   bitstring against each pattern in turn.  If none of the patterns
   match then the standard library [Match_failure] exception is
   thrown.

   Patterns look a bit different from normal match patterns.  They
   consist of a list of bitfields separated by [;] where each bitfield
   contains a bind variable, the width (in bits) of the field, and
   other information.  Some example patterns:

{[
bitmatch bits with

| { version : 8; name : 8; param : 8 } -> ...

   (* Bitstring of at least 3 bytes.  First byte is the version
      number, second byte is a field called name, third byte is
      a field called parameter. *)

| { flag : 1 } ->
   printf "flag is %b\n" flag

   (* A single flag bit (mapped into an OCaml boolean). *)

| { len : 4; data : 1+len } ->
   printf "len = %d, data = 0x%Lx\n" len data

   (* A 4-bit length, followed by 1-16 bits of data, where the
      length of the data is computed from len. *)

| { ipv6_source : 128 : bitstring;
    ipv6_dest : 128 : bitstring } -> ...

   (* IPv6 source and destination addresses.  Each is 128 bits
      and is mapped into a bitstring type which will be a substring
      of the main bitstring expression. *)
]}

   You can also add conditional when-clauses:

{[
| { version : 4 }
    when version = 4 || version = 6 -> ...

   (* Only match and run the code when version is 4 or 6.  If
      it isn't we will drop through to the next case. *)
]}

   Note that the pattern is only compared against the first part of
   the bitstring (there may be more data in the bitstring following
   the pattern, which is not matched).  In terms of regular
   expressions you might say that the pattern matches [^pattern], not
   [^pattern$].  To ensure that the bitstring contains only the
   pattern, add a length -1 bitstring to the end and test that its
   length is zero in the when-clause:

{[
| { n : 4;
    rest : -1 : bitstring }
    when Bitstring.bitstring_length rest = 0 -> ...

   (* Only matches exactly 4 bits. *)
]}

   Normally the first part of each field is a binding variable,
   but you can also match a constant, as in:

{[
| { (4|6) : 4 } -> ...

   (* Only matches if the first 4 bits contain either
      the integer 4 or the integer 6. *)
]}

   One may also match on strings:

{[
| { "MAGIC" : 5*8 : string } -> ...

   (* Only matches if the string "MAGIC" appears at the start
      of the input. *)
]}

   {3:patternfieldreference Pattern field reference}

   The exact format of each pattern field is:

   [pattern : length [: qualifier [,qualifier ...]]]

   [pattern] is the pattern, binding variable name, or constant to
   match.  [length] is the length in bits which may be either a
   constant or an expression.  The length expression is just an OCaml
   expression and can use any values defined in the program, and refer
   back to earlier fields (but not to later fields).

   Integers can only have lengths in the range \[1..64\] bits.  See the
   {{:#integertypes}integer types} section below for how these are
   mapped to the OCaml int/int32/int64 types.  This is checked
   at compile time if the length expression is constant, otherwise it is
   checked at runtime and you will get a runtime exception eg. in
   the case of a computed length expression.

   A bitstring field of length -1 matches all the rest of the
   bitstring (thus this is only useful as the last field in a
   pattern).

   A bitstring field of length 0 matches an empty bitstring
   (occasionally useful when matching optional subfields).

   Qualifiers are a list of identifiers/expressions which control the type,
   signedness and endianness of the field.  Permissible qualifiers are:

   - [int]: field has an integer type
   - [string]: field is a string type
   - [bitstring]: field is a bitstring type
   - [signed]: field is signed
   - [unsigned]: field is unsigned
   - [bigendian]: field is big endian - a.k.a network byte order
   - [littleendian]: field is little endian - a.k.a Intel byte order
   - [nativeendian]: field is same endianness as the machine
   - [endian (expr)]: [expr] should be an expression which evaluates to
       a {!endian} type, ie. [LittleEndian], [BigEndian] or [NativeEndian].
       The expression is an arbitrary OCaml expression and can use the
       value of earlier fields in the bitmatch.
   - [offset (expr)]: see {{:#computedoffsets}computed offsets} below.

   The default settings are [int], [unsigned], [bigendian], no offset.

   Note that many of these qualifiers cannot be used together,
   eg. bitstrings do not have endianness.  The syntax extension should
   give you a compile-time error if you use incompatible qualifiers.

   {3 Other cases in bitmatch}

   As well as a list of fields, it is possible to name the
   bitstring and/or have a default match case:

{[
| { _ } -> ...

   (* Default match case. *)

| { _ } as pkt -> ...

   (* Default match case, with 'pkt' bound to the whole bitstring. *)
]}

   {2 Constructing bitstrings}

   Bitstrings may be constructed using the [BITSTRING] operator (as an
   expression).  The [BITSTRING] operator takes a list of fields,
   similar to the list of fields for matching:

{[
let version = 1 ;;
let data = 10 ;;
let bits =
  BITSTRING {
    version : 4;
    data : 12
  } ;;

   (* Constructs a 16-bit bitstring with the first four bits containing
      the integer 1, and the following 12 bits containing the integer 10,
      arranged in network byte order. *)

Bitstring.hexdump_bitstring stdout bits ;;

   (* Prints:

      00000000  10 0a         |..              |
    *)
]}

   The format of each field is the same as for pattern fields (see
   {{:#patternfieldreference}Pattern field reference section}), and
   things like computed length fields, fixed value fields, insertion
   of bitstrings within bitstrings, etc. are all supported.

   {3 Construction exception}

   The [BITSTRING] operator may throw a {!Construct_failure}
   exception at runtime.

   Runtime errors include:

   - int field length not in the range \[1..64\]
   - a bitstring with a length declared which doesn't have the
     same length at runtime
   - trying to insert an out of range value into an int field
     (eg. an unsigned int field which is 2 bits wide can only
     take values in the range \[0..3\]).

   {2:integertypes Integer types}

   Integer types are mapped to OCaml types [bool], [int], [int32] or
   [int64] using a system which tries to ensure that (a) the types are
   reasonably predictable and (b) the most efficient type is
   preferred.

   The rules are slightly different depending on whether the bit
   length expression in the field is a compile-time constant or a
   computed expression.

   Detection of compile-time constants is quite simplistic so only
   simple integer literals and simple expressions (eg. [5*8]) are
   recognized as constants.

   In any case the bit size of an integer is limited to the range
   \[1..64\].  This is detected as a compile-time error if that is
   possible, otherwise a runtime check is added which can throw an
   [Invalid_argument] exception.

   The mapping is thus:

   {v
   Bit size	    ---- OCaml type ----
                Constant	Computed expression

   1		bool		int64
   2..31	int		int64
   32		int32		int64
   33..64	int64		int64
   v}

   A possible future extension may allow people with 64 bit computers
   to specify a more optimal [int] type for bit sizes in the range
   [32..63].  If this was implemented then such code {i could not even
   be compiled} on 32 bit platforms, so it would limit portability.

   Another future extension may be to allow computed
   expressions to assert min/max range for the bit size,
   allowing a more efficient data type than int64 to be
   used.  (Of course under such circumstances there would
   still need to be a runtime check to enforce the
   size).

   {2 Advanced pattern-matching features}

   {3:computedoffsets Computed offsets}

   You can add an [offset(..)] qualifier to bitmatch patterns in order
   to move the current offset within the bitstring forwards.

   For example:

{[
bitmatch bits with
| { field1 : 8;
    field2 : 8 : offset(160) } -> ...
]}

   matches [field1] at the start of the bitstring and [field2]
   at 160 bits into the bitstring.  The middle 152 bits go
   unmatched (ie. can be anything).

   The generated code is efficient.  If field lengths and offsets
   are known to be constant at compile time, then almost all
   runtime checks are avoided.  Non-constant field lengths and/or
   non-constant offsets can result in more runtime checks being added.

   Note that moving the offset backwards, and moving the offset in
   [BITSTRING] constructors, are both not supported at present.

   {3 Check expressions}

   You can add a [check(expr)] qualifier to bitmatch patterns.
   If the expression evaluates to false then the current match case
   fails to match (in other words, we fall through to the next
   match case - there is no error).

   For example:
{[
bitmatch bits with
| { field : 16 : check (field > 100) } -> ...
]}

   Note the difference between a check expression and a when-clause
   is that the when-clause is evaluated after all the fields have
   been matched.  On the other hand a check expression is evaluated
   after the individual field has been matched, which means it is
   potentially more efficient (if the check expression fails then
   we don't waste any time matching later fields).

   We wanted to use the notation [when(expr)] here, but because
   [when] is a reserved word we could not do this.

   {3 Bind expressions}

   A bind expression is used to change the value of a matched
   field.  For example:
{[
bitmatch bits with
| { len : 16 : bind (len * 8);
    field : len : bitstring } -> ...
]}

   In the example, after 'len' has been matched, its value would
   be multiplied by 8, so the width of 'field' is the matched
   value multiplied by 8.

   In the general case:
{[
| { field : ... : bind (expr) } -> ...
]}
   evaluates the following after the field has been matched:
{[
   let field = expr in
   (* remaining fields *)
]}

   {3 Order of evaluation of check() and bind()}

   The choice is arbitrary, but we have chosen that check expressions
   are evaluated first, and bind expressions are evaluated after.

   This means that the result of bind() is {i not} available in
   the check expression.

   Note that this rule applies regardless of the order of check()
   and bind() in the source code.

   {3 save_offset_to}

   Use [save_offset_to(variable)] to save the current bit offset
   within the match to a variable (strictly speaking, to a pattern).
   This variable is then made available in any [check()] and [bind()]
   clauses in the current field, {i and} to any later fields, and
   to the code after the [->].

   For example:
{[
bitmatch bits with
| { len : 16;
    _ : len : bitstring;
    field : 16 : save_offset_to (field_offset) } ->
      printf "field is at bit offset %d in the match\n" field_offset
]}

   (In that example, [field_offset] should always have the value
   [len+16]).

   {2 Named patterns and persistent patterns}

   Please see {!Bitstring_persistent} for documentation on this subject.

   {2 Compiling}

   Using the compiler directly you can do:

   {v
   ocamlc -I +bitstring \
     -pp "camlp4of bitstring.cma bitstring_persistent.cma \
            `ocamlc -where`/bitstring/pa_bitstring.cmo" \
     unix.cma bitstring.cma test.ml -o test
   v}

   Simpler method using findlib:

   {v
   ocamlfind ocamlc \
     -package bitstring,bitstring.syntax -syntax bitstring.syntax \
     -linkpkg test.ml -o test
   v}

   {2 Security and type safety}

   {3 Security on input}

   The main concerns for input are buffer overflows and denial
   of service.

   It is believed that this library is robust against attempted buffer
   overflows.  In addition to OCaml's normal bounds checks, we check
   that field lengths are >= 0, and many additional checks.

   Denial of service attacks are more problematic.  We only work
   forwards through the bitstring, thus computation will eventually
   terminate.  As for computed lengths, code such as this is thought
   to be secure:

   {[
   bitmatch bits with
   | { len : 64;
       buffer : Int64.to_int len : bitstring } ->
   ]}

   The [len] field can be set arbitrarily large by an attacker, but
   when pattern-matching against the [buffer] field this merely causes
   a test such as [if len <= remaining_size] to fail.  Even if the
   length is chosen so that [buffer] bitstring is allocated, the
   allocation of sub-bitstrings is efficient and doesn't involve an
   arbitary-sized allocation or any copying.

   However the above does not necessarily apply to strings used in
   matching, since they may cause the library to use the
   {!Bitstring.string_of_bitstring} function, which allocates a string.
   So you should take care if you use the [string] type particularly
   with a computed length that is derived from external input.

   The main protection against attackers should be to ensure that the
   main program will only read input bitstrings up to a certain
   length, which is outside the scope of this library.

   {3 Security on output}

   As with the input side, computed lengths are believed to be
   safe.  For example:

   {[
   let len = read_untrusted_source () in
   let buffer = allocate_bitstring () in
   BITSTRING {
     buffer : len : bitstring
   }
   ]}

   This code merely causes a check that buffer's length is the same as
   [len].  However the program function [allocate_bitstring] must
   refuse to allocate an oversized buffer (but that is outside the
   scope of this library).

   {3 Order of evaluation}

   In [bitmatch] statements, fields are evaluated left to right.

   Note that the when-clause is evaluated {i last}, so if you are
   relying on the when-clause to filter cases then your code may do a
   lot of extra and unncessary pattern-matching work on fields which
   may never be needed just to evaluate the when-clause.  Either
   rearrange the code to do only the first part of the match,
   followed by the when-clause, followed by a second inner bitmatch,
   or use a [check()] qualifier within fields.

   {3 Safety}

   The current implementation is believed to be fully type-safe,
   and makes compile and run-time checks where appropriate.  If
   you find a case where a check is missing please submit a
   bug report or a patch.

   {2 Limits}

   These are thought to be the current limits:

   Integers: \[1..64\] bits.

   Bitstrings (32 bit platforms): maximum length is limited
   by the string size, ie. 16 MBytes.

   Bitstrings (64 bit platforms): maximum length is thought to be
   limited by the string size, ie. effectively unlimited.

   Bitstrings must be loaded into memory before we can match against
   them.  Thus available memory may be considered a limit for some
   applications.

   {2:reference Reference}
   {3 Types}
*)

type endian = BigEndian | LittleEndian | NativeEndian

val string_of_endian : endian -> string
(** Endianness. *)

type bitstring = string * int * int
(** [bitstring] is the basic type used to store bitstrings.

    The type contains the underlying data (a string),
    the current bit offset within the string and the
    current bit length of the string (counting from the
    bit offset).  Note that the offset and length are
    in {b bits}, not bytes.

    Normally you don't need to use the bitstring type
    directly, since there are functions and syntax
    extensions which hide the details.

    See also {!bitstring_of_string}, {!bitstring_of_file},
    {!hexdump_bitstring}, {!bitstring_length}.
*)

type t = bitstring
(** [t] is a synonym for the {!bitstring} type.

    This allows you to use this module with functors like
    [Set] and [Map] from the stdlib. *)

(** {3 Exceptions} *)

exception Construct_failure of string * string * int * int
(** [Construct_failure (message, file, line, char)] may be
    raised by the [BITSTRING] constructor.

    Common reasons are that values are out of range of
    the fields that contain them, or that computed lengths
    are impossible (eg. negative length bitfields).

    [message] is the error message.

    [file], [line] and [char] point to the original source
    location of the [BITSTRING] constructor that failed.
*)

(** {3 Bitstring comparison} *)

val compare : bitstring -> bitstring -> int
(** [compare bs1 bs2] compares two bitstrings and returns zero
    if they are equal, a negative number if [bs1 < bs2], or a
    positive number if [bs1 > bs2].

    This tests "semantic equality" which is not affected by
    the offset or alignment of the underlying representation
    (see {!bitstring}).

    The ordering is total and lexicographic. *)

val equals : bitstring -> bitstring -> bool
(** [equals] returns true if and only if the two bitstrings are
    semantically equal.  It is the same as calling [compare] and
    testing if the result is [0], but usually more efficient. *)

(** {3 Bitstring manipulation} *)

val bitstring_length : bitstring -> int
(** [bitstring_length bitstring] returns the length of
    the bitstring in bits.

    Note this just returns the third field in the {!bitstring} tuple. *)

val bitstring_is_byte_aligned : bitstring -> bool
(** [bitstring_is_byte_aligned b] returns true if the data in
    [b] is byte-aligned. *)

val bitstring_write : bitstring -> int -> bitstring -> unit
(** [bitstring_write src offset dest] modifies [dest] in place
    by writing [src] starting at [offset] in [dest].

    Note that [offset] is currently in bytes *not* bits. *)

val bitstring_chop : int -> bitstring -> bitstring list
(** [bitstring_chop n bits] splits [bits] into a sequence of bitstrings,
    each of which (except maybe the last) having length [n] bits. *)

val bitstring_clip : bitstring -> int -> int -> bitstring
(** [bitstring_clip bits offset length] returns the bitstring which
    exists between [offset] and [offset + length] in [bits]. A bit is
    present in the result if it is both in [bits] and between [offset]
    and [offset + length]. *)

val subbitstring : bitstring -> int -> int -> bitstring
(** [subbitstring bits off len] returns a sub-bitstring
    of the bitstring, starting at offset [off] bits and
    with length [len] bits.

    If the original bitstring is not long enough to do this
    then the function raises [Invalid_argument "subbitstring"].

    Note that this function just changes the offset and length
    fields of the {!bitstring} tuple, so is very efficient. *)

val dropbits : int -> bitstring -> bitstring
(** Drop the first n bits of the bitstring and return a new
    bitstring which is shorter by n bits.

    If the length of the original bitstring is less than n bits,
    this raises [Invalid_argument "dropbits"].

    Note that this function just changes the offset and length
    fields of the {!bitstring} tuple, so is very efficient. *)

val takebits : int -> bitstring -> bitstring
(** Take the first n bits of the bitstring and return a new
    bitstring which is exactly n bits long.

    If the length of the original bitstring is less than n bits,
    this raises [Invalid_argument "takebits"].

    Note that this function just changes the offset and length
    fields of the {!bitstring} tuple, so is very efficient. *)

val concat : bitstring list -> bitstring
(** Concatenate a list of bitstrings together into a single
    bitstring. *)

(** {3 Constructing bitstrings} *)

val empty_bitstring : bitstring
(** [empty_bitstring] is the empty, zero-length bitstring. *)

val create_bitstring : int -> bitstring
(** [create_bitstring n] creates an [n] bit bitstring
    containing all zeroes. *)

val make_bitstring : int -> char -> bitstring
(** [make_bitstring n c] creates an [n] bit bitstring
    containing the repeated 8 bit pattern in [c].

    For example, [make_bitstring 16 '\x5a'] will create
    the bitstring [0x5a5a] or in binary [0101 1010 0101 1010].

    Note that the length is in bits, not bytes.  The length does NOT
    need to be a multiple of 8. *)

val zeroes_bitstring : int -> bitstring
(** [zeroes_bitstring] creates an [n] bit bitstring of all 0's.

    Actually this is the same as {!create_bitstring}. *)

val ones_bitstring : int -> bitstring
(** [ones_bitstring] creates an [n] bit bitstring of all 1's. *)

val bitstring_of_string : string -> bitstring
(** [bitstring_of_string str] creates a bitstring
    of length [String.length str * 8] (bits) containing the
    bits in [str].

    Note that the bitstring uses [str] as the underlying
    string (see the representation of {!bitstring}) so you
    should not change [str] after calling this. *)

val bitstring_of_chan : in_channel -> bitstring
(** [bitstring_of_chan chan] loads the contents of
    the input channel [chan] as a bitstring.

    The length of the final bitstring is determined
    by the remaining input in [chan], but will always
    be a multiple of 8 bits.

    See also {!bitstring_of_chan_max}. *)

val bitstring_of_chan_max : in_channel -> int -> bitstring
(** [bitstring_of_chan_max chan max] works like
    {!bitstring_of_chan} but will only read up to
    [max] bytes from the channel (or fewer if the end of input
    occurs before that). *)

(** {3 Converting bitstrings} *)

val string_of_bitstring : bitstring -> string
(** [string_of_bitstring bitstring] converts a bitstring to a string
    (eg. to allow comparison).

    This function is inefficient.  In the best case when the bitstring
    is nicely byte-aligned we do a [String.sub] operation.  If the
    bitstring isn't aligned then this involves a lot of bit twiddling
    and is particularly inefficient.

    If the bitstring is not a multiple of 8 bits wide then the
    final byte of the string contains the high bits set to the
    remaining bits and the low bits set to 0. *)

val bitstring_to_chan : bitstring -> out_channel -> unit
(** [bitstring_to_file bits filename] writes the bitstring [bits]
    to the channel [chan].

    Channels are made up of bytes, bitstrings can be any bit length
    including fractions of bytes.  So this function only works
    if the length of the bitstring is an exact multiple of 8 bits
    (otherwise it raises [Invalid_argument "bitstring_to_chan"]).

    Furthermore the function is efficient only in the case where
    the bitstring is stored fully aligned, otherwise it has to
    do inefficient bit twiddling like {!string_of_bitstring}.

    In the common case where the bitstring was generated by the
    [BITSTRING] operator and is an exact multiple of 8 bits wide,
    then this function will always work efficiently.
*)

(** {3 Printing bitstrings} *)

val hexdump_bitstring : out_channel -> bitstring -> unit
(** [hexdump_bitstring chan bitstring] prints the bitstring
    to the output channel in a format similar to the
    Unix command [hexdump -C]. *)

(** {3 Bitstring buffer} *)

module Buffer : sig
  type t
  val create : unit -> t
  val contents : t -> bitstring
  val add_bits : t -> string -> int -> unit
  val add_bit : t -> bool -> unit
  val add_byte : t -> int -> unit
end
(** Buffers are mainly used by the [BITSTRING] constructor, but
    may also be useful for end users.  They work much like the
    standard library [Buffer] module. *)

(** {3 Get/set bits}

    These functions let you manipulate individual bits in the
    bitstring.  However they are not particularly efficient and you
    should generally use the [bitmatch] and [BITSTRING] operators when
    building and parsing bitstrings.

    These functions all raise [Invalid_argument "index out of bounds"]
    if the index is out of range of the bitstring.
*)

val set : bitstring -> int -> unit
  (** [set bits n] sets the [n]th bit in the bitstring to 1. *)

val clear : bitstring -> int -> unit
  (** [clear bits n] sets the [n]th bit in the bitstring to 0. *)

val is_set : bitstring -> int -> bool
  (** [is_set bits n] is true if the [n]th bit is set to 1. *)

val is_clear : bitstring -> int -> bool
  (** [is_clear bits n] is true if the [n]th bit is set to 0. *)

val put : bitstring -> int -> int -> unit
  (** [put bits n v] sets the [n]th bit in the bitstring to 1
      if [v] is not zero, or to 0 if [v] is zero. *)

val get : bitstring -> int -> int
  (** [get bits n] returns the [n]th bit (returns non-zero or 0). *)

(** {3 Miscellaneous} *)

val package : string
(** The package name, always ["ocaml-bitstring"] *)

val version : string
(** The package version as a string. *)

val debug : bool ref
(** Set this variable to true to enable extended debugging.
    This only works if debugging was also enabled in the
    [pa_bitstring.ml] file at compile time, otherwise it
    does nothing. *)

(**/**)

(* Private functions, called from generated code.  Do not use
 * these directly - they are not safe.
 *)

(* 'extract' functions are used in bitmatch statements. *)

val extract_bit : string -> int -> int -> int -> bool

val extract_char_unsigned : string -> int -> int -> int -> int

val extract_int_be_unsigned : string -> int -> int -> int -> int

val extract_int_le_unsigned : string -> int -> int -> int -> int

val extract_int_ne_unsigned : string -> int -> int -> int -> int

val extract_int_ee_unsigned : endian -> string -> int -> int -> int -> int

val extract_int32_be_unsigned : string -> int -> int -> int -> int32

val extract_int32_le_unsigned : string -> int -> int -> int -> int32

val extract_int32_ne_unsigned : string -> int -> int -> int -> int32

val extract_int32_ee_unsigned : endian -> string -> int -> int -> int -> int32

val extract_int64_be_unsigned : string -> int -> int -> int -> int64

val extract_int64_le_unsigned : string -> int -> int -> int -> int64

val extract_int64_ne_unsigned : string -> int -> int -> int -> int64

val extract_int64_ee_unsigned : endian -> string -> int -> int -> int -> int64

external extract_fastpath_int16_be_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_be_unsigned" "noalloc"

external extract_fastpath_int16_le_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_le_unsigned" "noalloc"

external extract_fastpath_int16_ne_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_ne_unsigned" "noalloc"

external extract_fastpath_int16_be_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_be_signed" "noalloc"

external extract_fastpath_int16_le_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_le_signed" "noalloc"

external extract_fastpath_int16_ne_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_ne_signed" "noalloc"

(*
external extract_fastpath_int24_be_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_be_unsigned" "noalloc"

external extract_fastpath_int24_le_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_le_unsigned" "noalloc"

external extract_fastpath_int24_ne_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_ne_unsigned" "noalloc"

external extract_fastpath_int24_be_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_be_signed" "noalloc"

external extract_fastpath_int24_le_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_le_signed" "noalloc"

external extract_fastpath_int24_ne_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_ne_signed" "noalloc"
*)

external extract_fastpath_int32_be_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_be_unsigned" "noalloc"

external extract_fastpath_int32_le_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_le_unsigned" "noalloc"

external extract_fastpath_int32_ne_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_ne_unsigned" "noalloc"

external extract_fastpath_int32_be_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_be_signed" "noalloc"

external extract_fastpath_int32_le_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_le_signed" "noalloc"

external extract_fastpath_int32_ne_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_ne_signed" "noalloc"

(*
external extract_fastpath_int40_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_be_unsigned" "noalloc"

external extract_fastpath_int40_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_le_unsigned" "noalloc"

external extract_fastpath_int40_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_ne_unsigned" "noalloc"

external extract_fastpath_int40_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_be_signed" "noalloc"

external extract_fastpath_int40_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_le_signed" "noalloc"

external extract_fastpath_int40_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_ne_signed" "noalloc"

external extract_fastpath_int48_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_be_unsigned" "noalloc"

external extract_fastpath_int48_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_le_unsigned" "noalloc"

external extract_fastpath_int48_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_ne_unsigned" "noalloc"

external extract_fastpath_int48_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_be_signed" "noalloc"

external extract_fastpath_int48_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_le_signed" "noalloc"

external extract_fastpath_int48_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_ne_signed" "noalloc"

external extract_fastpath_int56_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_be_unsigned" "noalloc"

external extract_fastpath_int56_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_le_unsigned" "noalloc"

external extract_fastpath_int56_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_ne_unsigned" "noalloc"

external extract_fastpath_int56_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_be_signed" "noalloc"

external extract_fastpath_int56_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_le_signed" "noalloc"

external extract_fastpath_int56_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_ne_signed" "noalloc"
*)

external extract_fastpath_int64_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_be_unsigned" "noalloc"

external extract_fastpath_int64_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_le_unsigned" "noalloc"

external extract_fastpath_int64_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_ne_unsigned" "noalloc"

external extract_fastpath_int64_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_be_signed" "noalloc"

external extract_fastpath_int64_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_le_signed" "noalloc"

external extract_fastpath_int64_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_ne_signed" "noalloc"

(* 'construct' functions are used in BITSTRING constructors. *)
val construct_bit : Buffer.t -> bool -> int -> exn -> unit

val construct_char_unsigned : Buffer.t -> int -> int -> exn -> unit

val construct_int_be_unsigned : Buffer.t -> int -> int -> exn -> unit

val construct_int_le_unsigned : Buffer.t -> int -> int -> exn -> unit

val construct_int_ne_unsigned : Buffer.t -> int -> int -> exn -> unit

val construct_int_ee_unsigned : endian -> Buffer.t -> int -> int -> exn -> unit

val construct_int32_be_unsigned : Buffer.t -> int32 -> int -> exn -> unit

val construct_int32_le_unsigned : Buffer.t -> int32 -> int -> exn -> unit

val construct_int32_ne_unsigned : Buffer.t -> int32 -> int -> exn -> unit

val construct_int32_ee_unsigned : endian -> Buffer.t -> int32 -> int -> exn -> unit

val construct_int64_be_unsigned : Buffer.t -> int64 -> int -> exn -> unit

val construct_int64_le_unsigned : Buffer.t -> int64 -> int -> exn -> unit

val construct_int64_ne_unsigned : Buffer.t -> int64 -> int -> exn -> unit

val construct_int64_ee_unsigned : endian -> Buffer.t -> int64 -> int -> exn -> unit

val construct_string : Buffer.t -> string -> unit

val construct_bitstring : Buffer.t -> bitstring -> unit
