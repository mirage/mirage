(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

open Astring
open Action.Infix

type t = Device_graph.t

let if_keys =
  let open Device_graph in
  Device_graph.collect (module Key.Set) @@ function
  | If cond -> Key.deps cond
  | App | Dev _ -> Key.Set.empty

let all_keys =
  let open Device_graph in
  Device_graph.collect (module Key.Set) @@ function
  | Dev c -> Key.Set.of_list (Device.keys c)
  | If cond -> Key.deps cond
  | App -> Key.Set.empty

module Packages = struct
  type t = Package.t String.Map.t Key.value

  let union x y = Key.(pure (String.Map.union (fun _ -> Package.merge)) $ x $ y)

  let empty = Key.pure String.Map.empty
end

let packages t =
  let open Device_graph in
  let aux = function
    | Dev c ->
        let pkgs = Device.packages c in
        let aux x =
          String.Map.of_list (List.map (fun p -> (Package.name p, p)) x)
        in
        Key.(pure aux $ pkgs)
    | If _ | App -> Packages.empty
  in
  let return x = List.map snd (String.Map.bindings x) in
  Key.(pure return $ Device_graph.collect (module Packages) aux t)

let files info t =
  Device_graph.collect
    (module Fpath.Set)
    (function Dev c -> Device.files c info | If _ | App -> Fpath.Set.empty)
    t

module Dune = struct
  type t = Dune.stanza list

  let union = ( @ )

  let empty = []
end

let dune info =
  Device_graph.collect (module Dune) @@ function
  | Dev c -> Device.dune c info
  | If _ | App -> Dune.empty

(* [module_expresion tbl c args] returns the module expression of
   the functor [c] applies to [args]. *)
let module_expression fmt (c, args) =
  Fmt.pf fmt "%s%a" (Device.module_name c)
    Fmt.(list (parens @@ of_to_string @@ Device_graph.impl_name))
    args

let find_all_devices info g i =
  let ctx = Info.context info in
  let id = Impl.with_left_most_device ctx i { f = Device.id } in
  let p = function
    | Device_graph.Dev d -> Device.id d = id
    | App | If _ -> false
  in
  Device_graph.find_all g p

let iter_actions f t =
  let f v res = res >>= fun () -> f v in
  Device_graph.fold f t (Action.ok ())

let configure info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, _, _) -> Device.configure c info
  in
  iter_actions f t

let append_main i msg fmt =
  let path = Info.main i in
  let purpose = Fmt.strf "Append to main.ml (%s)" msg in
  Fmt.kstr
    (fun str ->
      Action.with_output ~path ~append:true ~purpose (fun ppf ->
          Fmt.pf ppf "%s@." str))
    fmt

let generate_modules info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, `Args args, `Deps _) ->
        if args = [] then Action.ok ()
        else
          append_main info "configure" "@[<2>module %s =@ %a@]@."
            (Device_graph.impl_name v) module_expression (c, args)
  in
  iter_actions f t

let meta_init fmt (connect_name, result_name) =
  Fmt.pf fmt "let _%s =@[@ Lazy.force %s @]in@ " result_name connect_name

let emit_connect fmt (iname, names, connect_string) =
  (* We avoid potential collision between double application
     by prefixing with "_". This also avoid warnings. *)
  let rnames = List.map (fun x -> "_" ^ x) names in
  let bind ppf name = Fmt.pf ppf "_%s >>= fun %s ->@ " name name in
  Fmt.pf fmt "@[<v 2>let %s = lazy (@ %a%a%s@ )@]@." iname
    Fmt.(list ~sep:nop meta_init)
    (List.combine names rnames)
    Fmt.(list ~sep:nop bind)
    rnames (connect_string rnames)

let emit_run info init main =
  (* "exit 1" is ok in this code, since cmdliner will print help. *)
  let force ppf name = Fmt.pf ppf "Lazy.force %s >>= fun _ ->@ " name in
  append_main info "emit_run"
    "@[<v 2>let () =@ let t =@ @[<v 2>%aLazy.force %s@]@ in run t@]"
    Fmt.(list ~sep:nop force)
    init main

let generate_connects ?(init = []) info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, `Args args, `Deps deps) ->
        let var_name = Device_graph.var_name v in
        let impl_name = Device_graph.impl_name v in
        let arg_names = List.map Device_graph.var_name (args @ deps) in
        append_main info "connect" "%a" emit_connect
          (var_name, arg_names, Device.connect c info impl_name)
  in
  iter_actions f t >>= fun () ->
  let main_name = Device_graph.var_name (Device_graph.find_root t) in
  let init_names =
    List.fold_left
      (fun acc i ->
        match find_all_devices info t i with
        | [] -> assert false
        | ds -> List.map Device_graph.var_name ds @ acc)
      [] init
    |> List.rev
  in
  emit_run info init_names main_name
