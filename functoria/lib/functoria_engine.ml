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
open Rresult
module Graph = Functoria_graph
module Key = Functoria_key
module Package = Functoria_package
module Device = Functoria.Device
module Impl = Functoria.Impl

type t = Graph.t

let if_keys =
  let open Graph in
  Graph.collect (module Key.Set) @@ function
  | If cond -> Key.deps cond
  | App | Dev _ -> Key.Set.empty

let all_keys =
  let open Graph in
  Graph.collect (module Key.Set) @@ function
  | Dev c -> Key.Set.of_list (Device.keys c)
  | If cond -> Key.deps cond
  | App -> Key.Set.empty

module M = struct
  type t = Package.t list Key.value

  let union x y = Key.(pure List.append $ x $ y)

  let empty = Key.pure []
end

let packages =
  let open Graph in
  Graph.collect (module M) @@ function
  | Dev c -> Device.packages c
  | If _ | App -> M.empty

(* [module_expresion tbl c args] returns the module expression of
   the functor [c] applies to [args]. *)
let module_expression fmt (c, args) =
  Fmt.pf fmt "%s%a" (Device.module_name c)
    Fmt.(list (parens @@ of_to_string @@ Graph.impl_name))
    args

let find_all_devices info g i =
  let ctx = Functoria.Info.context info in
  let id = Impl.with_left_most_device ctx i { f = Device.id } in
  let p = function Graph.Dev d -> Device.id d = id | App | If _ -> false in
  Graph.find_all g p

let build info t =
  let f v =
    match Graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Graph.D c, _, _) -> Device.build c info
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f t @@ R.ok ()

let configure info t =
  let f v =
    match Graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Graph.D c, `Args args, `Deps _) ->
        Device.configure c info >>| fun () ->
        if args = [] then ()
        else (
          Codegen.append_main "@[<2>module %s =@ %a@]" (Graph.impl_name v)
            module_expression (c, args);
          Codegen.newline_main () )
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f t @@ R.ok ()

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
    match Graph.explode t v with
    | `App _ | `If _ -> assert false
    | `Dev (Graph.D c, `Args args, `Deps deps) ->
        let var_name = Graph.var_name v in
        let impl_name = Graph.impl_name v in
        let arg_names = List.map Graph.var_name (args @ deps) in
        Codegen.append_main "%a" emit_connect
          (var_name, arg_names, Device.connect c info impl_name)
  in
  Graph.fold (fun v () -> f v) t ();
  let main_name = Graph.var_name (Graph.find_root t) in
  let init_names =
    List.fold_left
      (fun acc i ->
        match find_all_devices info t i with
        | [] -> assert false
        | ds -> List.map Graph.var_name ds @ acc)
      [] init
  in
  emit_run init_names main_name

let clean i g =
  let f v =
    match Graph.explode g v with
    | `App _ | `If _ -> assert false
    | `Dev (Graph.D c, _, _) -> Device.clean c i
  in
  let f v res = res >>= fun () -> f v in
  Graph.fold f g @@ R.ok ()
