(* Js_of_ocaml library
 * http://www.ocsigen.org/js_of_ocaml/
 * Copyright (C) 2010 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(** Javascript binding

    This module provides types and functions to interoperate with
    Javascript values, and gives access to Javascript standard
    objects.
*)

(** {2 Dealing with [null] and [undefined] values.} *)

type +'a opt
  (** Type of possibly null values. *)
type +'a optdef
  (** Type of possibly undefined values. *)

val null : 'a opt
  (** The [null] value. *)
val some : 'a -> 'a opt
  (** Consider a value into a possibly null value. *)
val undefined : 'a optdef
  (** The [undefined] value *)
val def : 'a -> 'a optdef
  (** Consider a value into a possibly undefined value. *)

(** Signatures of a set of standard functions for manipulating
    optional values. *)
module type OPT = sig
  type 'a t
  val empty : 'a t
    (** No value. *)
  val return : 'a -> 'a t
    (** Consider a value as an optional value. *)
  val map : 'a t -> ('a -> 'b) -> 'b t
    (** Apply a function to an optional value if it is available.
        Returns the result of the application. *)
  val bind : 'a t -> ('a -> 'b t) -> 'b t
    (** Apply a function returning an optional value to an optional value *)
  val test : 'a t -> bool
    (** Returns [true] if a value is available, [false] otherwise. *)
  val iter : 'a t -> ('a -> unit) -> unit
    (** Apply a function to an optional value if it is available. *)
  val case : 'a t -> (unit -> 'b) -> ('a -> 'b) -> 'b
    (** Pattern matching on optional values. *)
  val get : 'a t -> (unit -> 'a) -> 'a
    (** Get the value.  If no value available, an alternative function
        is called to get a default value. *)
  val option : 'a option -> 'a t
    (** Convert option type. *)
  val to_option : 'a t -> 'a option
    (** Convert to option type. *)
end

module Opt : OPT with type 'a t = 'a opt
  (** Standard functions for manipulating possibly null values. *)
module Optdef : OPT with type 'a t = 'a optdef
  (** Standard functions for manipulating possibly undefined values. *)

(** {2 Types for specifying method and properties of Javascript objects} *)

type +'a t
  (** Type of Javascript objects.  The type parameter is used to
      specify more precisely an object.  *)
type +'a meth
  (** Type used to specify method types:
      a Javascript object
        [<m : t1 -> t2 -> ... -> tn -> t Js.meth> Js.t]
      has a Javascript method [m] expecting {i n} arguments
      of types [t1] to [tn] and returns a value of type [t]. *)
type +'a gen_prop
  (** Type used to specify the properties of Javascript
      objects.  In practice you should rarely need this type directly,
      but should rather use the type abbreviations below instead. *)
type 'a readonly_prop = <get : 'a> gen_prop
  (** Type of read-only properties:
      a Javascript object
        [<p : t Js.readonly_prop> Js.t]
      has a read-only property [p] of type [t]. *)
type 'a writeonly_prop = <set : 'a -> unit> gen_prop
  (** Type of write-only properties:
      a Javascript object
        [<p : t Js.writeonly_prop> Js.t]
      has a write-only property [p] of type [t]. *)
type 'a prop = <get : 'a; set : 'a -> unit> gen_prop
  (** Type of read/write properties:
      a Javascript object
        [<p : t Js.writeonly_prop> Js.t]
      has a read/write property [p] of type [t]. *)
type 'a optdef_prop = <get : 'a optdef; set : 'a -> unit> gen_prop
  (** Type of read/write properties that may be undefined:
      you can set them to a value of some type [t], but if you read
      them, you will get a value of type [t optdef] (that may be
      [undefined]). *)
type float_prop = <get : float t; set : float -> unit> gen_prop
  (** Type of float properties:
      you can set them to an OCaml [float], but you will get back a
      native Javascript number of type [float t]. *)

(** {2 Object constructors} *)

type +'a constr
  (** A value of type [(t1 -> ... -> tn -> t Js.t) Js.constr] is a
      Javascript constructor expecting {i n} arguments of types [t1]
      to [tn] and returning a Javascript object of type [t Js.t].  Use
      the syntax extension [jsnew c (e1, ..., en)] to build an object
      using constructor [c] and arguments [e1] to [en]. *)

(** {2 Callbacks to OCaml} *)

type (-'a, +'b) meth_callback
   (** Type of callback functions.  A function of type
       [(u, t1 -> ... -> tn -> t) meth_callback] can be called
       from Javascript with [this] bound to a value of type [u]
       and up to {i n} arguments of types [t1] to [tn].  The system
       takes care of currification, so less than {i n} arguments can
       be provided.  As a special case, a callback of type
       [(t, unit -> t) meth_callback] can be called from Javascript
       with no argument.  It will behave as if it was called with a
       single argument of type [unit]. *)
type 'a callback = (unit, 'a) meth_callback
  (** Type of callback functions intended to be called without a
      meaningful [this] implicit parameter. *)

external wrap_callback : ('a -> 'b) -> ('c, 'a -> 'b) meth_callback =
    "caml_js_wrap_callback"
  (** Wrap an OCaml function so that it can be invoked from
      Javascript. *)
external wrap_meth_callback :
  ('c -> 'a -> 'b) -> ('c, 'a -> 'b) meth_callback =
    "caml_js_wrap_meth_callback"
  (** Wrap an OCaml function so that it can be invoked from
      Javascript.  The first parameter of the function will be bound
      to the value of the [this] implicit parameter. *)

(** {2 Javascript standard objects} *)

val _true : bool t
  (** Javascript [true] boolean. *)
val _false : bool t
  (** Javascript [false] boolean. *)

type match_result_handle
  (** A handle to a match result.  Use function [Js.match_result]
      to get the corresponding [MatchResult] object.
      (This type is used to resolved the mutual dependency between
       string and array type definitions.) *)
type string_array
  (** Opaque type for string arrays.  You can get the actual [Array]
      object using function [Js.str_array].
      (This type is used to resolved the mutual dependency between
       string and array type definitions.) *)

(** Specification of Javascript string objects. *)
class type js_string = object
  method toString : js_string t meth
  method valueOf : js_string t meth
  method charAt : int -> js_string t meth
  method charCodeAt : int -> float t meth        (* This may return NaN... *)
  method concat : js_string t -> js_string t meth
  method concat_2 : js_string t -> js_string t -> js_string t meth
  method concat_3 :
    js_string t -> js_string t -> js_string t -> js_string t meth
  method concat_4 :
    js_string t -> js_string t -> js_string t -> js_string t ->
    js_string t meth
  method indexOf : js_string t -> int meth
  method indexOf_from : js_string t -> int -> int meth
  method lastIndexOf : js_string t -> int meth
  method lastIndexOf_from : js_string t -> int -> int meth
  method localeCompare : js_string t -> float t meth
  method _match : regExp t -> match_result_handle t opt meth
  method replace : regExp t -> js_string t -> js_string t meth
  (* FIX: version of replace taking a function... *)
  method replace_string : js_string t -> js_string t -> js_string t meth
  method search : regExp t -> match_result_handle t opt meth
  method slice : int -> int -> js_string t meth
  method slice_end : int -> js_string t meth
  method split : js_string t -> string_array t meth
  method split_limited : js_string t -> int -> string_array t meth
  method split_regExp : regExp t -> string_array t meth
  method split_regExpLimited : regExp t -> int -> string_array t meth
  method substring : int -> int -> js_string t meth
  method substring_toEnd : int -> js_string t meth
  method toLowerCase : js_string t meth
  method toLocaleLowerCase : js_string t meth
  method toUpperCase : js_string t meth
  method toLocaleUpperCase : js_string t meth
  method length : int readonly_prop
end

(** Specification of Javascript regular expression objects. *)
and regExp = object
  method exec : js_string t -> match_result_handle t opt meth
  method test : js_string t -> bool t meth
  method toString : js_string t meth
  method source : js_string t readonly_prop
  method global : bool t readonly_prop
  method ignoreCase : bool t readonly_prop
  method multiline : bool t readonly_prop
  method lastIndex : int prop
end

val regExp : (js_string t -> regExp t) constr
  (** Constructor of [RegExp] objects.  The expression [jsnew regExp (s)]
      builds the regular expression specified by string [s]. *)
val regExp_withFlags : (js_string t -> js_string t -> regExp t) constr
  (** Constructor of [RegExp] objects.  The expression
      [jsnew regExp (s, f)] builds the regular expression specified by
      string [s] using flags [f]. *)
val regExp_copy : (regExp t -> regExp t) constr
  (** Constructor of [RegExp] objects.  The expression
      [jsnew regExp (r)] builds a copy of regular expression [r]. *)

(** Specification of Javascript regular arrays. *)
class type ['a] js_array = object
  method toString : js_string t meth
  method toLocaleString : js_string t meth
  method concat : 'a js_array t -> 'a js_array t meth
  method join : js_string t -> js_string t meth
  method pop : 'a optdef meth
  method push : 'a -> int meth
  method push_2 : 'a -> 'a -> int meth
  method push_3 : 'a -> 'a -> 'a -> int meth
  method push_4 : 'a -> 'a -> 'a -> 'a -> int meth
  method reverse : 'a js_array t meth
  method shift : 'a optdef meth
  method slice : int -> int -> 'a js_array t meth
  method slice_end : int -> 'a js_array t meth
  method sort : ('a -> 'a -> float) callback -> 'a js_array t meth
  method sort_asStrings : 'a js_array t meth
  method splice : int -> int -> 'a js_array t meth
  method splice_1 : int -> int -> 'a -> 'a js_array t meth
  method splice_2 : int -> int -> 'a -> 'a -> 'a js_array t meth
  method splice_3 : int -> int -> 'a -> 'a -> 'a -> 'a js_array t meth
  method splice_4 : int -> int -> 'a -> 'a -> 'a -> 'a -> 'a js_array t meth
  method unshift : 'a -> int meth
  method unshift_2 : 'a -> 'a -> int meth
  method unshift_3 : 'a -> 'a -> 'a -> int meth
  method unshift_4 : 'a -> 'a -> 'a -> 'a -> int meth
  method length : int prop
end

val array_empty : 'a js_array t constr
  (** Constructor of [Array] objects.  The expression
      [jsnew array_empty ()] returns an empty array. *)
val array_length : (int -> 'a js_array t) constr
  (** Constructor of [Array] objects.  The expression
      [jsnew array_empty (l)] returns an array of length [l]. *)

val array_get : 'a #js_array t -> int -> 'a optdef
  (** Array access: [array_get a i] returns the element at index [i]
      of array [a].  Returns [undefined] if there is no element at
      this index. *)
val array_set : 'a #js_array t -> int -> 'a -> unit
  (** Array update: [array_set a i v] puts [v] at index [i] in
      array [a]. *)

(** Specification of match result objects *)
class type match_result = object
  inherit [js_string t] js_array
  method index : int readonly_prop
  method input : js_string t readonly_prop
end

val str_array : string_array t -> js_string t js_array t
  (** Convert an opaque [string_array t] object into an array of
      string.  (Used to resolved the mutual dependency between string
      and array type definitions.) *)
val match_result : match_result_handle t -> match_result t
  (** Convert a match result handle into a [MatchResult] object.
      (Used to resolved the mutual dependency between string
      and array type definitions.) *)

(** Specification of Javascript number objects. *)
class type number = object
  method toString : js_string t meth
  method toString_radix : int -> js_string t meth
  method toLocaleString : js_string t meth
  method toFixed : int -> js_string t meth
  method toExponential : js_string t meth
  method toExponential_digits : int -> js_string t meth
  method toPrecision : int -> js_string meth t
end

external number_of_float : float -> number t = "caml_js_from_float"
  (** Conversion of OCaml floats to Javascript number objects. *)
external float_of_number : number t -> float = "caml_js_to_float"
  (** Conversion of Javascript number objects to OCaml floats. *)

(** Specification of Javascript date objects. *)
class type date = object
  method toString : js_string t meth
  method toDateString : js_string t meth
  method toTimeString : js_string t meth
  method toLocaleString : js_string t meth
  method toLocaleDateString : js_string t meth
  method toLocaleTimeString : js_string t meth
  method valueOf : float t meth
  method getTime : float t meth
  method getFullYear : int meth
  method getUTCFullYear : int meth
  method getMonth : int meth
  method getUTCMonth : int meth
  method getDate : int meth
  method getUTCDate : int meth
  method getDay : int meth
  method getUTCDay : int meth
  method getHours : int meth
  method getUTCHours : int meth
  method getMinutes : int meth
  method getUTCMinutes : int meth
  method getSeconds : int meth
  method getUTCSeconds : int meth
  method getMilliseconds : int meth
  method getUTCMilliseconds : int meth
  method getTimezoneOffset : int meth
  method setTime : float -> float t meth
  method setFullYear : int -> float t meth
  method setUTCFullYear : int -> float t meth
  method setMonth : int -> float t meth
  method setUTCMonth : int -> float t meth
  method setDate : int -> float t meth
  method setUTCDate : int -> float t meth
  method setDay : int -> float t meth
  method setUTCDay : int -> float t meth
  method setHours : int -> float t meth
  method setUTCHours : int -> float t meth
  method setMinutes : int -> float t meth
  method setUTCMinutes : int -> float t meth
  method setSeconds : int -> float t meth
  method setUTCSeconds : int -> float t meth
  method setMilliseconds : int -> float t meth
  method setUTCMilliseconds : int -> float t meth
  method toUTCString : js_string t meth
  method toISOString : js_string t meth
  method toJSON : 'a -> js_string t meth
end

val date_now : date t constr
  (** Constructor of [Date] objects: [new date_now ()] returns a
      [Date] object initialized with the current date. *)
val date_fromTimeValue : (float -> date t) constr
  (** Constructor of [Date] objects: [new date_fromTimeValue (t)] returns a
      [Date] object initialized with the time value [t]. *)
val date_month : (int -> int -> date t) constr
  (** Constructor of [Date] objects: [new date_fromTimeValue (y, m)]
      returns a [Date] object corresponding to year [y] and month [m]. *)
val date_day : (int -> int -> int -> date t) constr
  (** Constructor of [Date] objects: [new date_fromTimeValue (y, m, d)]
      returns a [Date] object corresponding to year [y], month [m] and
      day [d]. *)
val date_hour : (int -> int -> int -> int -> date t) constr
  (** Constructor of [Date] objects: [new date_fromTimeValue (y, m, d, h)]
      returns a [Date] object corresponding to year [y] to hour [h]. *)
val date_min : (int -> int -> int -> int -> int -> date t) constr
  (** Constructor of [Date] objects: [new date_fromTimeValue (y, m, d, h, m')]
      returns a [Date] object corresponding to year [y] to minute [m']. *)
val date_sec : (int -> int -> int -> int -> int -> int -> date t) constr
  (** Constructor of [Date] objects:
      [new date_fromTimeValue (y, m, d, h, m', s)]
      returns a [Date] object corresponding to year [y] to second [s]. *)
val date_ms : (int -> int -> int -> int -> int -> int -> int -> date t) constr
  (** Constructor of [Date] objects:
      [new date_fromTimeValue (y, m, d, h, m', s, ms)]
      returns a [Date] object corresponding to year [y]
      to millisecond [ms]. *)

(** Specification of the date constructor, considered as an object. *)
class type date_constr = object
  method parse : js_string t -> float t meth
  method _UTC_month : int -> int -> float t meth
  method _UTC_day : int -> int -> float t meth
  method _UTC_hour : int -> int -> int -> int -> float t meth
  method _UTC_min : int -> int -> int -> int -> int -> float t meth
  method _UTC_sec : int -> int -> int -> int -> int -> int -> float t meth
  method _UTC_ms :
    int -> int -> int -> int -> int -> int -> int -> float t meth
  method now : float t meth
end

val date : date_constr t
  (** The date constructor, as an object. *)

(** Specification of Javascript math object. *)
class type math = object
  method random : float t meth
end

val math : math t
  (** The Math object *)

(** {2 Standard Javascript functions} *)

val decodeURI : js_string t -> js_string t
  (** Decode a URI: replace by the corresponding byte all escape
      sequences but the ones corresponding to a URI reserved character
      and convert the string from UTF-8 to UTF-16. *)
val decodeURIComponent : js_string t -> js_string t
  (** Decode a URIComponent: replace all escape sequences by the
      corresponding byte and convert the string from UTF-8 to
      UTF-16. *)
val encodeURI : js_string t -> js_string t
  (** Encode a URI: convert the string to UTF-8 and replace all unsafe
      bytes by the corresponding escape sequence. *)
val encodeURIComponent : js_string t -> js_string t
  (** Same as [encodeURI], but also encode URI reserved characters. *)
val escape : js_string t -> js_string t
  (** Escape a string: unsafe UTF-16 code points are replaced by
      2-digit and 4-digit escape sequences. *)
val unescape : js_string t -> js_string t
  (** Unescape a string: 2-digit and 4-digit escape sequences are
      replaced by the corresponding UTF-16 code point. *)

(** {2 Conversion functions between Javascript and OCaml types} *)

external bool : bool -> bool t = "caml_js_from_bool"
  (** Conversion of booleans from OCaml to Javascript. *)
external to_bool : bool t -> bool = "caml_js_to_bool"
  (** Conversion of booleans from Javascript to OCaml. *)
external string : string -> js_string t = "caml_js_from_string"
  (** Conversion of strings from OCaml to Javascript.  (The OCaml
      string is considered to be encoded in UTF-8 and is converted to
      UTF-16.) *)
external to_string : js_string t -> string = "caml_js_to_string"
  (** Conversion of strings from Javascript to OCaml. *)
external float : float -> float t = "caml_js_from_float"
  (** Conversion of OCaml floats to Javascript numbers. *)
external to_float : float t -> float = "caml_js_to_float"
  (** Conversion of Javascript numbers to OCaml floats. *)
external array : 'a array -> 'a js_array t = "caml_js_from_array"
  (** Conversion of arrays from OCaml to Javascript. *)
external to_array : 'a js_array t -> 'a array = "caml_js_to_array"
  (** Conversion of arrays from Javascript to OCaml. *)
external bytestring : string -> js_string t = "caml_js_from_byte_string"
  (** Conversion of strings of bytes from OCaml to Javascript.
      (Each byte will be converted in an UTF-16 code point.) *)
external to_bytestring : js_string t -> string = "caml_js_to_byte_string"
  (** Conversion of strings of bytes from Javascript to OCaml.  (The
      Javascript string should only contain UTF-16 code points below
      255.) *)

(** {2 Convenience coercion functions} *)

val coerce : 'a -> ('a -> 'b Opt.t) -> ('a -> 'b) -> 'b
  (** Apply a possibly failing coercion function.
      [coerce v c f] attempts to apply coercion [c] to value [v].
      If the coercion returns [null], function [f] is called. *)
val coerce_opt : 'a Opt.t -> ('a -> 'b Opt.t) -> ('a -> 'b) -> 'b
  (** Apply a possibly failing coercion function.
      [coerce_opt v c f] attempts to apply coercion [c] to value [v].
      If [v] is [null] or the coercion returns [null], function [f] is
      called.
      Typical usage is the following:
      {[Js.coerce_opt (Dom_html.getElementById id)
      Dom_html.CoerceTo.div (fun _ -> assert false)]} *)

(** {2 Type checking operators.} *)

external typeof : < .. > t -> js_string t = "caml_js_typeof"
  (** Returns the type of a Javascript object. *)

external instanceof : < .. > t -> _ constr -> bool = "caml_js_instanceof"
  (** Tests whether a Javascript object is an instance of a given class. *)

(** {2 Unsafe operations.} *)

(** Unsafe Javascript operations *)
module Unsafe : sig
  external variable : string -> 'a = "caml_js_var"
    (** Access a Javascript variable.  [variable "foo"] will
        return the current value of variable [foo]. *)

  type any
    (** Top type.  Used for putting values of different types
        in a same array. *)
  external inject : 'a -> any = "%identity"
    (** Coercion to top type. *)
  external coerce : < .. > t -> < ..> t = "%identity"
    (** Unsafe coercion between to Javascript objects. *)
  external get : 'a -> 'b -> 'c = "caml_js_get"
    (** Get the value of an object property.  The expression [get o s]
        returns the value of property [s] of object [o]. *)
  external set : 'a -> 'b -> 'c -> unit = "caml_js_set"
    (** Set an object property.  The expression [set o s v]
        set the property [s] of object [o] to value [v]. *)
  external call : 'a -> 'b -> any array -> 'c = "caml_js_call"
    (** Performs a Javascript function call.  The expression
        [call f o a] calls the Javascript function [f] with the
        arguments given by the array [o], and binding [this] to [o]. *)
  external fun_call : 'a -> any array -> 'b = "caml_js_fun_call"
    (** Performs a Javascript function call.  The expression
        [fun_call f a] calls the Javascript function [f] with the
        arguments given by the array [o]. *)
  external meth_call : 'a -> string -> any array -> 'b = "caml_js_meth_call"
    (** Performs a Javascript method call.  The expression
        [meth_call o m a] calls the Javascript method [m] of object [o]
        with the arguments given by the array [a]. *)
  external new_obj : 'a -> any array -> 'b = "caml_js_new"
    (** Create a Javascript object.  The expression [new_obj c a]
        creates a Javascript object with constructor [c] using the
        arguments given by the array [a]. *)

  external pure_expr : (unit -> 'a) -> 'a = "caml_js_pure_expr"
    (** Asserts that an expression is pure, and can therefore be
        optimized away by the compiler if unused. *)

  external eval_string : string -> 'a = "caml_js_eval_string"
    (** Evaluate Javascript code *)

(*FIX also, object/array literals *)
end
