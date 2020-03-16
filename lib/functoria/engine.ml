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
  type t = Package.t list Key.value

  let union x y = Key.(pure List.append $ x $ y)

  let empty = Key.pure []
end

let packages =
  let open Device_graph in
  Device_graph.collect (module Packages) @@ function
  | Dev c -> Device.packages c
  | If _ | App -> Packages.empty

let check_conflicts i g =
  let packages = Key.eval (Info.context i) (packages g) in
  let package_names = packages |> List.map Package.name |> String.Set.of_list in
  List.fold_left
    (fun acc pkg ->
      List.fold_left
        (fun acc c ->
          if String.Set.mem c package_names then (pkg, c) :: acc else acc)
        acc (Package.conflicts pkg))
    [] packages

module Installs = struct
  type t = Install.t Key.value

  let union x y = Key.(pure Install.union $ x $ y)

  let empty = Key.pure Install.empty
end

let install i =
  let open Device_graph in
  Device_graph.collect (module Installs) @@ function
  | Dev c -> Device.install c i
  | If _ | App -> Installs.empty

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

let build info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, _, _) -> Device.build c info
  in
  let f v res = res >>= fun () -> f v in
  Device_graph.fold f t @@ Action.ok ()

let configure info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, `Args args, `Deps _) ->
        Device.configure c info >|= fun () ->
        if args = [] then ()
        else (
          Codegen.append_main "@[<2>module %s =@ %a@]"
            (Device_graph.impl_name v) module_expression (c, args);
          Codegen.newline_main () )
  in
  let f v res = res >>= fun () -> f v in
  Device_graph.fold f t @@ Action.ok ()

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

let emit_run init main =
  (* "exit 1" is ok in this code, since cmdliner will print help. *)
  let force ppf name = Fmt.pf ppf "Lazy.force %s >>= fun _ ->@ " name in
  Codegen.append_main
    "@[<v 2>let () =@ let t =@ @[<v 2>%aLazy.force %s@]@ in run t@]"
    Fmt.(list ~sep:nop force)
    init main

let connect ?(init = []) info t =
  let f v =
    match Device_graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, `Args args, `Deps deps) ->
        let var_name = Device_graph.var_name v in
        let impl_name = Device_graph.impl_name v in
        let arg_names = List.map Device_graph.var_name (args @ deps) in
        Codegen.append_main "%a" emit_connect
          (var_name, arg_names, Device.connect c info impl_name)
  in
  Device_graph.fold (fun v () -> f v) t ();
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
  emit_run init_names main_name

let clean i g =
  let f v =
    match Device_graph.explode g v with
    | `App _ | `If _ -> assert false
    | `Dev (Device_graph.D c, _, _) -> Device.clean c i
  in
  let f v res = res >>= fun () -> f v in
  Device_graph.fold f g @@ Action.ok ()
