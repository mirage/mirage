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

module Keys = struct
  type t = Key.Set.t

  let union a b = Key.Set.union a b
  let empty = Key.Set.empty
end

let keys x =
  Impl.collect
    (module Keys)
    (function
      | Dev c -> Key.Set.of_list (Device.keys c)
      | If cond -> Key.deps cond
      | App -> Keys.empty)
    x

module Runtime_args = struct
  type t = Runtime_arg.Set.t

  let union a b = Runtime_arg.Set.union a b
  let empty = Runtime_arg.Set.empty
end

let runtime_args x =
  Impl.collect
    (module Runtime_args)
    (function
      | Dev c -> Runtime_arg.Set.of_list (Device.runtime_args c)
      | If _ -> Runtime_args.empty
      | App -> Runtime_args.empty)
    x

module Packages = struct
  type t = Package.Set.t Key.value

  let union x y = Key.(pure Package.Set.union $ x $ y)
  let empty = Key.pure Package.Set.empty
end

let packages t =
  let open Impl in
  let aux = function
    | Dev c ->
        let pkgs = Device.packages c in
        let runtime_args = Device.runtime_args c in
        let extra_pkgs =
          List.fold_left
            (fun acc k ->
              let pkgs = Runtime_arg.packages k in
              Package.Set.(union acc (of_list pkgs)))
            Package.Set.empty runtime_args
        in
        let aux x = Package.Set.(union (of_list x) extra_pkgs) in
        Key.(pure aux $ pkgs)
    | If _ | App -> Packages.empty
  in
  let return x = Package.Set.to_list x in
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
    Fmt.(
      list ~sep:(any "")
        (any "(" ++ of_to_string Device.Graph.impl_name ++ any ")"))
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

let lines_of_str str =
  String.fold_left (fun n -> function '\n' -> n + 1 | _ -> n) 0 str

type main = { dir : Fpath.t; path : Fpath.t; mutable lines : int }

let main info =
  let path = Info.main info in
  let dir = Fpath.(Info.(parent (config_file info) / project_name info)) in
  let+ str = Action.read_file path in
  let lines = lines_of_str str in
  { dir; path; lines }

let append_main main msg fmt =
  let purpose = Fmt.str "Append to main.ml (%s)" msg in
  Fmt.kstr
    (fun str ->
      main.lines <- main.lines + lines_of_str str + 1;
      Action.with_output ~path:main.path ~append:true ~purpose (fun ppf ->
          Fmt.pf ppf "%s@." str))
    fmt

let configure info t =
  let* main = main info in
  let f (v : t) =
    let (D { dev; args; _ }) = v in
    let* () = Device.configure dev info in
    if args = [] then Action.ok ()
    else
      append_main main "configure" "module %s = %a\n" (Device.Graph.impl_name v)
        module_expression (dev, args)
  in
  iter_actions f t

let meta_init fmt (connect_name, result_name) =
  Fmt.pf fmt "  let _%s = Lazy.force %s in@ " result_name connect_name

let pp_pos ppf = function
  | None -> ()
  | Some (file, line, _, _) -> Fmt.pf ppf "# %d %S@." line file

let reset_pos { dir; path; lines } =
  let file = Fpath.(dir // path) |> Fpath.normalize |> Fpath.to_string in
  Some (file, lines + 1, 0, 0)

let emit_connect fmt (iname, names, runtime_args, connect_code) =
  (* We avoid potential collision between double application
     by prefixing with "_". This also avoid warnings. *)
  let rnames = List.map (fun x -> "_" ^ x) names in
  let knames = List.map (fun k -> "_" ^ Runtime_arg.var_name k) runtime_args in
  let bind ppf name = Fmt.pf ppf "  _%s >>= fun %s ->\n" name name in
  let bind_key ppf k =
    Fmt.pf ppf "  let _%s = %a in\n" (Runtime_arg.var_name k) Runtime_arg.call k
  in
  let { Device.pos; code } = connect_code (rnames @ knames) in
  Fmt.pf fmt "let %s = lazy (\n%a%a%a%a  %s@\n);;" iname
    Fmt.(list ~sep:nop meta_init)
    (List.combine names rnames)
    Fmt.(list ~sep:nop bind)
    rnames
    Fmt.(list ~sep:nop bind_key)
    runtime_args pp_pos pos code

let emit_run main init main_name =
  (* "exit 1" is ok in this code, since cmdliner will print help. *)
  let force ppf name = Fmt.pf ppf "Lazy.force %s >>= fun _ ->\n  " name in
  append_main main "emit_run"
    "let () =\n  let t = %aLazy.force %s in\n  run t\n;;"
    Fmt.(list ~sep:nop force)
    init main_name

let connect ?(init = []) info t =
  let* main = main info in
  let f (v : t) =
    let (D { dev; args; deps; _ }) = v in
    let var_name = Device.Graph.var_name v in
    let impl_name = Device.Graph.impl_name v in
    let arg_names = List.map Device.Graph.var_name (args @ deps) in
    let runtime_args = Device.runtime_args dev in
    let* () =
      append_main main "connect" "%a" emit_connect
        (var_name, arg_names, runtime_args, Device.connect dev info impl_name)
    in
    append_main main "reset" "%a" pp_pos (reset_pos main)
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
  emit_run main init_names main_name
