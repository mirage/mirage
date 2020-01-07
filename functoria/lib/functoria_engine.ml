(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

open Functoria_misc
open Astring
open Rresult

module Graph = Functoria_graph
module Key = Functoria_key
module Package = Functoria_package

type t = Graph.t

let if_keys =
  let open Graph in
  Graph.collect (module Key.Set) @@ function
  | If cond      -> Key.deps cond
  | App | Impl _ -> Key.Set.empty

let all_keys =
  let open Graph in
  Graph.collect (module Key.Set) @@ function
  | Impl c  -> Key.Set.of_list c#keys
  | If cond -> Key.deps cond
  | App     -> Key.Set.empty

module M = struct
  type t = Package.t list Key.value
  let union x y = Key.(pure List.append $ x $ y)
  let empty = Key.pure []
end

let packages =
  let open Graph in
  Graph.collect (module M) @@ function
  | Impl c     -> c#packages
  | If _ | App -> M.empty

(* Return a unique variable name holding the state of the given
   module construction. *)
let name c id =
  let prefix = Name.ocamlify c#name in
  Name.create (Fmt.strf "%s%i" prefix id) ~prefix

(* [module_expresion tbl c args] returns the module expression of
   the functor [c] applies to [args]. *)
let module_expression tbl fmt (c, args) =
  Fmt.pf fmt "%s%a"
    c#module_name
    Fmt.(list (parens @@ of_to_string @@ Graph.Tbl.find tbl))
    args

(* [module_name tbl c args] return the module name of the result of
   the functor application. If [args = []], it returns
   [c#module_name]. *)
let module_name c id args =
  let base = c#module_name in
  if args = [] then base
  else
    let prefix = match String.cut ~sep:"." base with
      | Some (l, _) -> l
      | None -> base
    in
    let prefix = Name.ocamlify prefix in
    Name.create (Fmt.strf "%s%i" prefix id) ~prefix

(* FIXME: Can we do better than lookup by name? *)
let find_device info g i =
  let open Functoria in
  let ctx = Info.context info in
  let rec name: type a . a impl -> string = fun impl ->
    match explode impl with
    | `Impl c              -> c#name
    | `App (Abstract x, _) -> name x
    | `If (b, x, y)        -> if Key.eval ctx b then name x else name y
  in
  let name = name i in
  let open Graph in
  let p = function
    | Impl c     -> c#name = name
    | App | If _ -> false
  in
  match Graph.find_all g p with
  | []  -> invalid_arg "Functoria.find_device: no device"
  | [x] -> x
  | _   -> invalid_arg "Functoria.find_device: too many devices."

let build info t =
  let f v = match Graph.explode t v with
    | `App _ | `If _ -> R.ok ()
    | `Impl (c, _, _) -> c#build info
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f t @@ R.ok ()

let configure info t =
  let tbl = Graph.Tbl.create 17 in
  let f v = match Graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Impl (c, `Args args, `Deps _) ->
      let modname = module_name c (Graph.hash v) args in
      Graph.Tbl.add tbl v modname;
      c#configure info >>| fun () ->
      if args = [] then ()
      else begin
        Codegen.append_main
          "@[<2>module %s =@ %a@]"
          modname
          (module_expression tbl) (c,args);
        Codegen.newline_main ();
      end
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f t @@ R.ok () >>| fun () ->
  tbl

let meta_init fmt (connect_name, result_name) =
  Fmt.pf fmt "let _%s =@[@ Lazy.force %s @]in@ " result_name connect_name

let emit_connect fmt (iname, names, connect_string) =
  (* We avoid potential collision between double application
     by prefixing with "_". This also avoid warnings. *)
  let rnames = List.map (fun x -> "_"^x) names in
  let bind ppf name =
    Fmt.pf ppf "_%s >>= fun %s ->@ " name name
  in
  Fmt.pf fmt
    "@[<v 2>let %s = lazy (@ \
     %a\
     %a\
     %s@ )@]@."
    iname
    Fmt.(list ~sep:nop meta_init) (List.combine names rnames)
    Fmt.(list ~sep:nop bind) rnames
    (connect_string rnames)

let emit_run init main =
  (* "exit 1" is ok in this code, since cmdliner will print help. *)
  let force ppf name =
    Fmt.pf ppf "Lazy.force %s >>= fun _ ->@ " name
  in
  Codegen.append_main
    "@[<v 2>\
     let () =@ \
     let t =@ @[<v 2>%aLazy.force %s@]@ \
     in run t@]"
    Fmt.(list ~sep:nop force) init main

let connect ?(init=[]) ~modules info t =
  let tbl = Graph.Tbl.create 17 in
  let f v = match Graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Impl (c, `Args args, `Deps deps) ->
      let ident = name c (Graph.hash v) in
      let modname = Graph.Tbl.find modules v in
      Graph.Tbl.add tbl v ident;
      let names = List.map (Graph.Tbl.find tbl) (args @ deps) in
      Codegen.append_main "%a"
        emit_connect (ident, names, c#connect info modname)
  in
  Graph.fold (fun v () -> f v) t ();
  let main_name = Graph.Tbl.find tbl @@ Graph.find_root t in
  let init_names =
    List.map (fun name -> Graph.Tbl.find tbl @@ find_device info t name) init
  in
  emit_run init_names main_name;
  ()

type modules = string Graph.Tbl.t

let configure_and_connect ?init info g =
  configure info g >>| fun modules ->
  connect ~modules info ?init g

let clean i g =
  let f v = match Graph.explode g v with
    | `Impl (c,_,_) -> c#clean i
    | _ -> R.ok ()
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f g @@ R.ok ()
