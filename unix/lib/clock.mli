(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Clock operations.
    Currently read-only to retrieve the time in various formats. *)

type tm =
  { tm_sec : int;               (** Seconds 0..60 *)
    tm_min : int;               (** Minutes 0..59 *)
    tm_hour : int;              (** Hours 0..23 *)
    tm_mday : int;              (** Day of month 1..31 *)
    tm_mon : int;               (** Month of year 0..11 *)
    tm_year : int;              (** Year - 1900 *)
    tm_wday : int;              (** Day of week (Sunday is 0) *)
    tm_yday : int;              (** Day of year 0..365 *)
    tm_isdst : bool;            (** Daylight time savings in effect *)
  }

val time : unit -> float
(** Return the current time since 00:00:00 GMT, Jan. 1, 1970, in seconds. *)

val gmtime : float -> tm
(** Convert a time in seconds, as returned by {!OS.Clock.time}, into a date and
   a time. Assumes UTC (Coordinated Universal Time), also known as GMT. *)
