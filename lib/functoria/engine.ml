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
open Action.Syntax

type t = Device.Graph.t

let if_keys x =
  Impl.collect
    (module Key.Set)
    (function If cond -> Key.deps cond | App | Dev _ -> Key.Set.empty)
    x

let all_keys x =
  Impl.collect
    (module Key.Set)
    (function
      | Dev c -> Key.Set.of_list (Device.keys c)
      | If cond -> Key.deps cond
      | App -> Key.Set.empty)
    x

module Packages = struct
  type t = Package.t String.Map.t Key.value

  let union x y = Key.(pure (String.Map.union (fun _ -> Package.merge)) $ x $ y)

  let empty = Key.pure String.Map.empty
end

let packages t =
  let open Impl in
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
  Key.(pure return $ Impl.collect (module Packages) aux t)

module Installs = struct
  type t = Install.t Key.value

  let union x y = Key.(pure Install.union $ x $ y)

  let empty = Key.pure Install.empty
end

let install i x =
  Impl.collect
    (module Installs)
    (function Dev c -> Device.install c i | If _ | App -> Installs.empty)
    x

let files info t =
  Impl.collect
    (module Fpath.Set)
    (function Dev c -> Device.files c info | If _ | App -> Fpath.Set.empty)
    t

module Dune = struct
  type t = Dune.stanza list

  let union = ( @ )

  let empty = []
end

let dune info =
  Impl.collect (module Dune) @@ function
  | Dev c -> Device.dune c info
  | If _ | App -> Dune.empty

(* [module_expresion tbl c args] returns the module expression of
   the functor [c] applies to [args]. *)
let module_expression fmt (c, args) =
  Fmt.pf fmt "%s%a" (Device.module_name c)
    Fmt.(list (parens @@ of_to_string @@ Device.Graph.impl_name))
    args

let find_all_devices info g i =
  let ctx = Info.context info in
  let id = Impl.with_left_most_device ctx i { f = Device.id } in
  let f x l =
    let (Device.Graph.D { dev; _ }) = x in
    if Device.id dev = id then x :: l else l
  in
  Device.Graph.fold f g []

let iter_actions f t =
  let f v res =
    let* () = res in
    f v
  in
  Device.Graph.fold f t (Action.ok ())

let append_main i msg fmt =
  let path = Info.main i in
  let purpose = Fmt.str "Append to main.ml (%s)" msg in
  Fmt.kstr
    (fun str ->
      Action.with_output ~path ~append:true ~purpose (fun ppf ->
          Fmt.pf ppf "%s@." str))
    fmt

let configure info t =
  let f (v : t) =
    let (D { dev; args; _ }) = v in
    let* () = Device.configure dev info in
    if args = [] then Action.ok ()
    else
      append_main info "configure" "@[<2>module %s =@ %a@]@."
        (Device.Graph.impl_name v) module_expression (dev, args)
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

let connect ?(init = []) info t =
  let f (v : t) =
    let (D { dev; args; deps; _ }) = v in
    let var_name = Device.Graph.var_name v in
    let impl_name = Device.Graph.impl_name v in
    let arg_names = List.map Device.Graph.var_name (args @ deps) in
    append_main info "connect" "%a" emit_connect
      (var_name, arg_names, Device.connect dev info impl_name)
  in
  let* () = iter_actions f t in
  let main_name = Device.Graph.var_name t in
  let init_names =
    List.fold_left
      (fun acc i ->
        match find_all_devices info t i with
        | [] -> assert false
        | ds -> List.map Device.Graph.var_name ds @ acc)
      [] init
    |> List.rev
  in
  emit_run info init_names main_name
