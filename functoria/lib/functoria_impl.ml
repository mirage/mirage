(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2015-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
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

module Codegen = Functoria_misc.Codegen
module Key = Functoria_key
module Info = Functoria_info
module Device = Functoria_device
module Type = Functoria_type
module Package = Functoria_package
open Astring
open Rresult

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

type _ t =
  | Dev : 'ty device -> 'ty t (* base devices *)
  | App : ('a, 'b) app -> 'b t (* functor application *)
  | If : bool Key.value * 'a t * 'a t -> 'a t

and ('a, 'b) app = { f (* functor *) : ('a -> 'b) t; x (* parameter *) : 'a t }

and 'a device = ('a, abstract) Device.t

and abstract = Abstract : _ t -> abstract

let abstract t = Abstract t

let of_device v = Dev v

let if_ b x y = If (b, x, y)

let rec match_ kv ~default = function
  | [] -> default
  | (f, i) :: t -> If (Key.(pure (( = ) f) $ kv), i, match_ kv ~default t)

let ( $ ) f x = App { f; x }

let v ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?build ?clean
    module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?keys ?extra_deps ?connect ?configure ?build
       ?clean module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  v ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

let rec pp : type a. a t Fmt.t =
 fun ppf -> function
  | Dev d -> Fmt.pf ppf "Dev %a" (Device.pp pp_abstract) d
  | App a -> Fmt.pf ppf "App %a" pp_app a
  | If (_, x, y) -> Fmt.pf ppf "If (_,%a,%a)" pp x pp y

and pp_app : type a b. (a, b) app Fmt.t =
 fun ppf t -> Fmt.pf ppf "{@[ f: %a;@, x: %a @]}" pp t.f pp t.x

and pp_abstract ppf (Abstract i) = pp ppf i

module Keys = struct
  let with_output f k =
    Bos.OS.File.with_oc f k ()
    >>= R.reword_error_msg (fun _ ->
            `Msg (Fmt.strf "couldn't open output channel %a" Fpath.pp f))

  let configure ~file i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    with_output file (fun oc () ->
        let fmt = Format.formatter_of_out_channel oc in
        Codegen.append fmt "(* %s *)" (Codegen.generated_header ());
        Codegen.newline fmt;
        let keys = Key.Set.of_list @@ Info.keys i in
        let pp_var k = Key.serialize (Info.context i) k in
        Fmt.pf fmt "@[<v>%a@]@." (Fmt.iter Key.Set.iter pp_var) keys;
        let runvars = Key.Set.elements (Key.filter_stage `Run keys) in
        let pp_runvar ppf v = Fmt.pf ppf "%s_t" (Key.ocaml_name v) in
        let pp_names ppf v = Fmt.pf ppf "%S" (Key.name v) in
        Codegen.append fmt "let runtime_keys = List.combine %a %a"
          Fmt.Dump.(list pp_runvar)
          runvars
          Fmt.Dump.(list pp_names)
          runvars;
        Codegen.newline fmt;
        Ok ())

  let clean ~file _ = Bos.OS.Path.delete file
end

let keys (argv : Type.argv t) =
  let packages = [ Package.v "functoria-runtime" ] in
  let extra_deps = [ abstract argv ] in
  let module_name = Key.module_name in
  let file = Fpath.(v (String.Ascii.lowercase module_name) + "ml") in
  let configure = Keys.configure ~file and clean = Keys.clean ~file in
  let connect info impl_name = function
    | [ argv ] ->
        Fmt.strf
          "return (Functoria_runtime.with_argv (List.map fst %s.runtime_keys) \
           %S %s)"
          impl_name (Info.name info) argv
    | _ -> failwith "The keys connect should receive exactly one argument."
  in
  v ~configure ~clean ~packages ~extra_deps ~connect module_name Type.job

(* Module emiting a file containing all the build information. *)

let pp_libraries fmt l =
  Fmt.pf fmt "[@ %a]" Fmt.(iter ~sep:(unit ";@ ") List.iter @@ fmt "%S") l

let pp_packages fmt l =
  Fmt.pf fmt "[@ %a]"
    Fmt.(
      iter ~sep:(unit ";@ ") List.iter @@ fun fmt (n, v) -> pf fmt "%S, %S" n v)
    l

let pp_dump_pkgs fmt (name, pkg, libs) =
  Fmt.pf fmt
    "Functoria_runtime.{@ name = %S;@ @[<v 2>packages = %a@]@ ;@ @[<v \
     2>libraries = %a@]@ }"
    name pp_packages (String.Map.bindings pkg) pp_libraries
    (String.Set.elements libs)

(* this used to call 'opam list --rec ..', but that leads to
   non-reproducibility, since this uses the opam CUDF solver which
   drops some packages (which are in the repositories configured for
   the switch), see https://github.com/mirage/functoria/pull/189 for
   further discussion on this before changing the code below.

   This also used to call `opam list --installed --required-by <pkgs>`,
   but that was not precise enough as this was 1/ computing the
   dependencies for all version of <pkgs> and 2/ keeping only the
   installed packages. `opam list --installed --resolve <pkgs>` will
   compute the dependencies of the installed versions of <pkgs>.  *)
let default_opam_deps pkgs =
  let pkgs_str = String.concat ~sep:"," pkgs in
  let cmd =
    Bos.Cmd.(
      v "opam"
      % "list"
      % "--installed"
      % "-s"
      % "--color=never"
      % "--depopts"
      % "--resolve"
      % pkgs_str
      % "--columns"
      % "name,version")
  in
  Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_lines >>= fun (deps, _) ->
  let deps =
    List.fold_left
      (fun acc s ->
        match String.cuts ~empty:false ~sep:" " s with
        | [ n; v ] -> (n, v) :: acc
        | _ -> assert false)
      [] deps
  in
  let deps = String.Map.of_list deps in
  let roots = String.Set.of_list pkgs in
  let deps = String.Set.fold String.Map.remove roots deps in
  Ok deps

let app_info ?opam_deps ?(gen_modname = "Info_gen") () =
  let file = Fpath.(v (String.Ascii.lowercase gen_modname) + "ml") in
  let module_name = gen_modname in
  let packages = [ Package.v "functoria-runtime" ] in
  let connect _ impl_name _ = Fmt.strf "return %s.info" impl_name in
  let clean _ = Bos.OS.Path.delete file in
  let build i =
    Log.info (fun m -> m "Generating: %a" Fpath.pp file);
    let opam_deps =
      match opam_deps with
      | None -> default_opam_deps (Info.package_names i)
      | Some pkgs -> Ok (String.Map.of_list pkgs)
    in
    opam_deps >>= fun opam ->
    let ocl = String.Set.of_list (Info.libraries i) in
    Bos.OS.File.writef file "@[<v 2>let info = %a@]" pp_dump_pkgs
      (Info.name i, opam, ocl)
  in
  v ~packages ~connect ~clean ~build module_name Type.info

(* Noop, the job that does nothing. *)
let noop = v "Unit" Type.job

let sys_argv =
  let connect _ _ _ = "return Sys.argv" in
  v ~connect "Sys" Type.argv

let rec hash : type a. a t -> int = function
  | Dev c -> Device.hash c
  | App { f; x } -> Hashtbl.hash (hash f, hash x)
  | If (cond, t, e) -> Hashtbl.hash (cond, hash t, hash e)

let hash_abstract (Abstract x) = hash x

let rec equal : type t1 t2. t1 t -> t2 t -> bool =
 fun x y ->
  match (x, y) with
  | Dev c, Dev c' -> Device.equal c c'
  | App a, App b -> equal a.f b.f && equal a.x b.x
  | If (cond1, t1, e1), If (cond2, t2, e2) ->
      (* Key.value is a functional value (it contains a closure for eval).
         There is no prettier way than physical equality. *)
      cond1 == cond2 && equal t1 t2 && equal e1 e2
  | _ -> false

let equal_abtract (Abstract a) (Abstract b) = equal a b

module Tbl = Hashtbl.Make (struct
  type t = abstract

  let hash = hash_abstract

  let equal = equal_abtract
end)

type 'b f_dev = { f : 'a. ('a, abstract) Device.t -> 'b }

type 'a f_if = cond:bool Key.value -> then_:'a -> else_:'a -> 'a

type 'a f_app = f:'a -> x:'a -> 'a

let with_left_most_device ctx t { f } =
  let rec aux : type a. a t -> _ = function
    | Dev d -> f d
    | App a -> aux a.f
    | If (b, x, y) -> if Key.eval ctx b then aux x else aux y
  in
  aux t

let map (type r) ~if_ ~app ~dev t =
  let tbl = Tbl.create 50 in
  let rec aux : type a. a t -> r =
   fun impl ->
    if Tbl.mem tbl @@ abstract impl then Tbl.find tbl (abstract impl)
    else
      let acc =
        match impl with
        | Dev d ->
            let deps =
              List.fold_right
                (fun (Abstract x) l -> aux x :: l)
                (Device.extra_deps d) []
            in
            dev.f d ~deps
        | App a ->
            let f = aux a.f in
            let x = aux a.x in
            app ~f ~x
        | If (cond, then_, else_) ->
            let then_ = aux then_ in
            let else_ = aux else_ in
            if_ ~cond ~then_ ~else_
      in
      Tbl.add tbl (abstract impl) acc;
      acc
  in
  aux t
