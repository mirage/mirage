(******************************************************************************
 *                             Type-conv                                      *
 *                                                                            *
 * Copyright (C) 2005- Jane Street Holding, LLC                               *
 *    Contact: opensource@janestreet.com                                      *
 *    WWW: http://www.janestreet.com/ocaml                                    *
 *    Author: Markus Mottl                                                    *
 *                                                                            *
 * This library is free software; you can redistribute it and/or              *
 * modify it under the terms of the GNU Lesser General Public                 *
 * License as published by the Free Software Foundation; either               *
 * version 2 of the License, or (at your option) any later version.           *
 *                                                                            *
 * This library is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          *
 * Lesser General Public License for more details.                            *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public           *
 * License along with this library; if not, write to the Free Software        *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  *
 *                                                                            *
 ******************************************************************************)

(** Pa_type_conv: Preprocessing Module for Registering Type Conversions *)

open Camlp4.PreCast.Ast

(** {6 Generator registration} *)

val add_generator : ?is_exn : bool -> string -> (ctyp -> str_item) -> unit
(** [add_generator ?is_exn name gen] adds the code generator [gen],
    which maps type or exception declarations to structure items, where
    [is_exn] specifies whether the declaration is an exception.  Note that
    the original type/exception declarations get added automatically in
    any case.

    @param is_exn = [false]
*)

val add_generator_with_arg :
  ?is_exn : bool -> string -> 'a Camlp4.PreCast.Gram.Entry.t ->
  (ctyp -> 'a option -> str_item) -> unit
(** [add_generator_with_arg ?is_exn name entry generator] same as
    [add_generator], but the generator may accept an argument, which is
    parsed with [entry]. *)

val rm_generator : ?is_exn : bool -> string -> unit
(** [rm_generator ?is_exn name] removes the code generator named [name]. *)

val add_sig_generator :
  ?is_exn : bool -> string -> (ctyp -> sig_item) -> unit
(** [add_generator ?is_exn name gen] adds the code generator [gen],
    which maps type or exception declarations to signature items, where
    [is_exn] specifies whether the declaration is an exception.  Note that
    the original type/exception declarations get added automatically in
    any case.

    @param is_exn = [false]
*)

val set_conv_path_if_not_set : Loc.t -> unit

val add_sig_generator_with_arg :
  ?is_exn : bool -> string -> 'a Camlp4.PreCast.Gram.Entry.t ->
  (ctyp -> 'a option -> sig_item) -> unit
(** [add_sig_generator_with_arg ?is_exn name entry generator] same as
    [add_sig_generator], but the generator may accept an argument,
    which is parsed with [entry]. *)

val rm_sig_generator : ?is_exn : bool -> string -> unit
(** [rm_sig_generator name] removes the code signature generator named
    [name]. *)

val get_conv_path : unit -> string
(** [get_conv_path ()] @return the name to module containing a type
    as required for error messages. *)


(** {6 Utility functions} *)

val get_loc_err : Loc.t -> string -> string
(** [get_loc_err loc msg] generates a compile-time error message. *)

val hash_variant : string -> int
(** [hash_variant str] @return the integer encoding a variant tag with
    name [str]. *)


(** {6 General purpose code generation module} *)

module Gen : sig

  val exApp_of_list : expr list -> expr
  (** [expr_app_of_list l] takes a list of expressions [e1;e2;e3...] and returns
      the expression [e1 e2 e3]. c.f.: Ast.exSem_of_list *)

  val tyArr_of_list : ctyp list -> ctyp
  (** [tyArr_of_list l] takes a list of types [e1;e2;e3...] and returns
      the type [e1 e2 e3]. c.f.: Ast.exSem_of_list *)

  val paOr_of_list : patt list -> patt
  (** [paOr_of_list l] takes a list of patterns [p1;p2;p3...] and returns the
      pattern [p1 | p2 | p3]... *)

  val gensym : ?prefix:string -> unit -> string
  (** [gensym ?prefix ()] generates a fresh variable name with the prefix
      [prefix]. The default value for prefix is "_x". When used with the default
      parameters it will generate return: [_x__001],[_x__002],[_x__003]...
  *)

  val error : ctyp -> fn:string -> msg:string -> _
  (** [error tp ~fn ~msg] raises an error with [msg] on type [tp]
      occuring in function [fn] *)

  val unknown_type : ctyp -> string -> _
  (** [unknown_type tp fn] type [tp] is not handled by the function [fn] *)

  val ty_var_list_of_ctyp : ctyp -> string list -> string list
  (** [ty_var_list_of_ctyp tp acc] accumulates a list of type parameters
      contained in [tp] into [acc] as strings. *)

  val get_rev_id_path : ident -> string list -> string list
  (** [get_rev_id_path id acc] takes an identifier.  @return a reversed
      module path (list of strings) denoting this identifier, appending
      it to [acc]. *)

  val ident_of_rev_path : Loc.t -> string list -> ident
  (** [ident_of_rev_path loc path] takes a location [loc] and a reversed path
      [rev_path] to an identifier.  @return identifier denoting the
      bound value. *)

  val get_appl_path : Loc.t -> ctyp -> ident
  (** [get_appl_path loc tp] @return the identifier path associated with
      a polymorphic type. *)

  val abstract : Loc.t -> patt list -> expr -> expr
  (** [abstract loc patts body] takes a location [loc], a pattern list
      [patts], and an expression [body].  @return a function expression
      that takes the patterns as arguments, and binds them in [body]. *)

  val apply : Loc.t -> expr -> expr list -> expr
  (** [apply loc f_expr arg_exprs] takes a location [loc], an expression
      [f_expr] representing a function, and a list of argument expressions
      [arg_exprs].  @return an expression in which the function is
      applied to its arguments. *)

  val idp : Loc.t -> string -> patt
  (* DEPRECATED: use quotations instead*)
  (** [idp loc name] @return a pattern matching a lowercase identifier
      [name]. *)

  val ide : Loc.t -> string -> expr
  (* DEPRECATED: use quotations instead*)
  (** [ide loc name] @return an expression of a lowercase identifier
      [name]. *)

  val switch_tp_def :
    alias : (Loc.t -> ctyp -> 'a) ->
    sum : (Loc.t -> ctyp -> 'a) ->
    record : (Loc.t -> ctyp -> 'a) ->
    variants : (Loc.t -> ctyp -> 'a) ->
    mani : (Loc.t -> ctyp -> ctyp -> 'a) ->
    nil : (Loc.t -> 'a) ->
    ctyp
    -> 'a
  (** [switch_tp_def ~alias ~sum ~record ~variants ~mani tp_def]
      takes a handler function for each kind of type definition and
      applies the appropriate handler when [tp_def] matches. *)

  val mk_expr_lst : Loc.t -> expr list -> expr
  (** [mk_expr_lst loc expr_list] takes a list of expressions.
      @return an expression representing a list of expressions. *)

  val mk_patt_lst : Loc.t -> patt list -> patt
  (** [mk_patt_lst _loc patt_list] takes a list of patterns.
      @return a pattern representing a list of patterns. *)

  val get_tparam_id : ctyp -> string
  (** [get_tparam_id tp] @return the string identifier associated with
      [tp] if it is a type parameter.  @raise Failure otherwise. *)

  val type_is_recursive : string -> ctyp -> bool
  (** [type_is_recursive _loc id tp] @return whether the type [tp]
      with name [id] refers to itself, assuming that it is not mutually
      recursive with another type. *)

  val drop_variance_annotations : ctyp -> ctyp
  (** [drop_variance_annotations _loc tp] @return the type resulting
      from dropping all variance annotations in [tp]. *)
end
