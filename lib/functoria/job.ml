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

let src = Logs.Src.create "functoria" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

type t = JOB

let t = Type.v JOB

(* Noop, the job that does nothing. *)
let noop = Impl.v "Unit" t

module Args = struct
  let configure ~runtime_modname i =
    let serialize = Runtime_arg.serialize ~runtime_modname in
    let file = Info.main i in
    Action.with_output ~append:true ~path:file ~purpose:"keys" (fun ppf ->
        let keys = Runtime_arg.Set.of_list @@ Info.runtime_args i in
        Fmt.pf ppf "@[<v>%a@]@." Fmt.(iter Runtime_arg.Set.iter serialize) keys)
end

let runtime_args
    ?(runtime_package = Package.v "mirage-runtime" ~sublibs:[ "functoria" ])
    ?(runtime_modname = "Functoria_runtime") (argv : Argv.t Impl.t) =
  let packages = [ runtime_package ] in
  let extra_deps = [ Impl.abstract argv ] in
  let configure = Args.configure ~runtime_modname in
  let connect info _ = function
    | [ argv ] ->
        Device.code ~pos:__POS__ "return %s.(with_argv (runtime_args ()) %S %s)"
          runtime_modname (Info.name info) argv
    | _ -> failwith "The keys connect should receive exactly one argument."
  in
  Impl.v ~configure ~packages ~extra_deps ~connect "struct end" t
