module Dune = Functoria.Dune
module Info = Functoria.Info
module Install = Functoria.Install
open Functoria.DSL
open Functoria.Action

type block = BLOCK

let block = typ BLOCK

type block_t = { filename : string; number : int }

let all_blocks = Hashtbl.create 7

let make_block_t =
  (* NB: reserve number 0 for the boot disk *)
  let next_number = ref 1 in
  fun filename ->
    let b =
      if Hashtbl.mem all_blocks filename then Hashtbl.find all_blocks filename
      else
        let number = !next_number in
        incr next_number;
        let b = { filename; number } in
        Hashtbl.add all_blocks filename b;
        b
    in
    b

let xen_block_packages =
  [ package ~min:"2.1.0" ~max:"3.0.0" ~sublibs:[ "front" ] "mirage-block-xen" ]

(* this function takes a string rather than an int as `id` to allow
   the user to pass stuff like "/dev/xvdi1", which mirage-block-xen
   also understands *)
let xenstore_conf id =
  let configure i =
    match Misc.get_target i with
    | `Qubes | `Xen -> ok ()
    | _ ->
        error
          "XenStore IDs are only valid ways of specifying block devices when \
           the target is Xen or Qubes."
  in
  let connect _ impl_name _ = code ~pos:__POS__ "%s.connect %S" impl_name id in
  impl ~configure ~connect ~packages:xen_block_packages "Block" block

let block_of_xenstore_id id = xenstore_conf id

(* calculate the XenStore ID for the nth available block device.
   Taken from https://github.com/mirage/mirage-block-xen/blob/
   a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 . *)
let xenstore_id_of_index number =
  if number < 16 then (202 lsl 8) lor (number lsl 4)
  else (1 lsl 28) lor (number lsl 8)

let block_conf file =
  let connect_name target =
    match target with
    | #Key.mode_unix -> file (* open the file directly *)
    | #Key.mode_xen ->
        let b = make_block_t file in
        xenstore_id_of_index b.number |> string_of_int
    | #Key.mode_solo5 ->
        (* XXX For now, on Solo5, just pass the "file" name through directly as
         * the Solo5 block device name *)
        file
    | #Key.mode_unikraft -> file
  in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | #Key.mode_xen -> xen_block_packages
    | #Key.mode_solo5 ->
        [ package ~min:"0.8.0" ~max:"0.9.0" "mirage-block-solo5" ]
    | #Key.mode_unix ->
        [ package ~min:"2.12.0" ~max:"3.0.0" "mirage-block-unix" ]
    | #Key.mode_unikraft ->
        [ package ~min:"1.0.0" ~max:"2.0.0" "mirage-block-unikraft" ]
  in
  let configure _ =
    let (_ : block_t) = make_block_t file in
    ok ()
  in
  let connect i s _ =
    match Misc.get_target i with
    | `Muen -> failwith "Block devices not supported on Muen target."
    | _ ->
        code ~pos:__POS__ "%s.connect %S" s (connect_name (Misc.get_target i))
  in
  Functoria.Device.v ~configure ~packages_v ~connect "Block" block

let block_of_file file = of_device (block_conf file)

let ramdisk rname =
  let packages = [ package "mirage-block-ramdisk" ] in
  let connect _ m _ = code ~pos:__POS__ "%s.connect ~name:%S" m rname in
  impl ~connect ~packages "Ramdisk" block

let generic_block ?group ?(key = Key.(value @@ block ?group ())) name =
  match_impl key
    [
      (`XenstoreId, block_of_xenstore_id name);
      (`BlockFile, block_of_file name);
      (`Ramdisk, ramdisk name);
    ]
    ~default:(ramdisk name)

let tar_kv_ro_conf =
  let packages = [ package ~min:"1.0.0" ~max:"4.0.0" "tar-mirage" ] in
  let connect _ modname = function
    | [ block ] -> code ~pos:__POS__ "%s.connect %s" modname block
    | _ -> Misc.connect_err "tar_kv_ro" 1
  in
  impl ~packages ~connect "Tar_mirage.Make_KV_RO" (block @-> Kv.ro)

let tar_kv_rw_conf =
  let packages = [ package ~min:"2.2.0" ~max:"4.0.0" "tar-mirage" ] in
  let connect _ modname = function
    | [ block ] -> code ~pos:__POS__ "%s.connect %s" modname block
    | _ -> Misc.connect_err "tar_kv_rw" 1
  in
  impl ~packages ~connect "Tar_mirage.Make_KV_RW" (block @-> Kv.rw)

let tar_kv_ro block = tar_kv_ro_conf $ block
let tar_kv_rw block = tar_kv_rw_conf $ block

let fat_conf =
  let packages = [ package ~min:"0.15.0" ~max:"0.16.0" "fat-filesystem" ] in
  let connect _ modname = function
    | [ block ] -> code ~pos:__POS__ "%s.connect %s" modname block
    | _ -> Misc.connect_err "fat" 1
  in
  impl ~packages ~connect "Fat.KV_RO" (block @-> Kv.ro)

let fat_ro block = fat_conf $ block

type mode = [ `Fast | `Light ]

let pp_mode ppf = function
  | `Fast -> Fmt.string ppf "Fast"
  | `Light -> Fmt.string ppf "Light"

let pp_branch ppf = function
  | None -> ()
  | Some branch -> Fmt.pf ppf " -b %s" branch

let docteur_unix (mode : mode) extra_deps ~name:_ ~output branch analyze remote
    =
  let dune info =
    let ctx = Info.context info in
    let output = Key.get ctx output in
    let source_tree =
      let uri = Uri.of_string remote in
      match Uri.scheme uri with
      | Some "file" ->
          let path = Uri.host_with_default ~default:"" uri ^ Uri.path uri in
          Fmt.str " (source_tree /%s)" path
      | Some "relativize" ->
          let path = Uri.host_with_default ~default:"" uri ^ Uri.path uri in
          Fmt.str " (source_tree %s)" path
      | _ -> ""
    in
    let dune =
      Dune.stanzaf
        {dune|
(rule
 (targets %s)
 (enabled_if (= %%{context_name} "default"))
 (deps (:make %%{bin:docteur.make})%a%s)
 (action (run %%{make} %s%a %s)))
|dune}
        output
        Fmt.(list ~sep:nop (const string " " ++ string))
        extra_deps source_tree remote pp_branch branch output
    in
    [ dune ]
  in
  let install info =
    let ctx = Info.context info in
    let output = Fpath.v (Key.get ctx output) in
    Install.v ~etc:[ output ] ()
  in
  let configure info =
    let ctx = Info.context info in
    let name = Key.get ctx output in
    let (_ : block_t) = make_block_t name in
    ok ()
  in
  let connect info modname = function
    | [ analyze ] ->
        let ctx = Info.context info in
        let name = Key.get ctx output in
        code ~pos:__POS__
          {ocaml|let ( <.> ) f g = fun x -> f (g x) in
             let f = Rresult.R.(failwith_error_msg <.> reword_error (msgf "%%a" %s.pp_error)) in
             Lwt.map f (%s.connect ~analyze:%s %S)|ocaml}
          modname modname analyze name
    | _ -> Misc.connect_err "docteur_unix" 1
  in
  let keys = [ Key.v output ] in
  let runtime_args = Runtime_arg.[ v analyze ] in
  let packages = [ package "docteur-unix" ~min:"0.0.6" ] in
  impl ~runtime_args ~keys ~packages ~dune ~install ~configure ~connect
    (Fmt.str "Docteur_unix.%a" pp_mode mode)
    Kv.ro

let docteur_solo5 (mode : mode) extra_deps ~name ~output branch analyze remote =
  let dune info =
    let ctx = Info.context info in
    let output = Key.get ctx output in
    let source_tree =
      let uri = Uri.of_string remote in
      match Uri.scheme uri with
      | Some "file" ->
          let path = Uri.host_with_default ~default:"" uri ^ Uri.path uri in
          Fmt.str " (source_tree /%s)" path
      | Some "relativize" ->
          let path = Uri.host_with_default ~default:"" uri ^ Uri.path uri in
          Fmt.str " (source_tree %s)" path
      | _ -> ""
    in
    let dune =
      Dune.stanzaf
        {dune|
(rule
 (targets %s)
 (enabled_if (= %%{context_name} "default"))
 (deps (:make %%{bin:docteur.make})%a%s)
 (action (run %%{make} %s%a %s)))
|dune}
        output
        Fmt.(list ~sep:nop (const string " " ++ string))
        extra_deps source_tree remote pp_branch branch output
    in
    [ dune ]
  in
  let install info =
    let ctx = Info.context info in
    let output = Fpath.v (Key.get ctx output) in
    Install.v ~etc:[ output ] ()
  in
  let configure info =
    let ctx = Info.context info in
    let name = Key.get ctx name in
    let (_ : block_t) = make_block_t name in
    ok ()
  in
  let connect info modname = function
    | [ analyze ] ->
        let ctx = Info.context info in
        let name = Key.get ctx name in
        code ~pos:__POS__
          {ocaml|let ( <.> ) f g = fun x -> f (g x) in
             let f = Rresult.R.(failwith_error_msg <.> reword_error (msgf "%%a" %s.pp_error)) in
             Lwt.map f (%s.connect ~analyze:%s %S)|ocaml}
          modname modname analyze name
    | _ -> Misc.connect_err "docteur_solo5" 1
  in
  let keys = [ Key.v output; Key.v name ] in
  let runtime_args = Runtime_arg.[ v analyze ] in
  let packages = [ package "docteur-solo5" ~min:"0.0.6" ] in
  impl ~keys ~runtime_args ~packages ~dune ~install ~configure ~connect
    (Fmt.str "Docteur_solo5.%a" pp_mode mode)
    Kv.ro

let disk_name =
  let doc =
    Cmdliner.Arg.info
      ~doc:
        "Name of the docteur disk (for Solo5 targets, the name must contains \
         only alpanumeric characters)."
      [ "disk-name" ]
  in
  let key = Key.Arg.opt Cmdliner.Arg.string "docteur" doc in
  Key.create "disk-name" key

let disk_output =
  let doc =
    Cmdliner.Arg.info ~doc:"The output of the generated docteur image."
      [ "disk-output" ]
  in
  let key = Key.Arg.opt Cmdliner.Arg.string "disk.img" doc in
  Key.create "disk-output" key

let docteur_solo5 (mode : mode) extra_deps ?(name = disk_name)
    ?(output = disk_output) branch analyze remote =
  docteur_solo5 mode extra_deps ~name ~output branch analyze remote

let docteur_unix (mode : mode) extra_deps ?(name = disk_name)
    ?(output = disk_output) branch analyze remote =
  docteur_unix mode extra_deps ~name ~output branch analyze remote

let analyze = Runtime_arg.create ~pos:__POS__ "Mirage_runtime.analyze"

let docteur ?(mode = `Fast) ?name ?output ?(analyze = analyze) ?branch
    ?(extra_deps = []) remote =
  match_impl
    Key.(value target)
    [
      (`Xen, docteur_solo5 mode extra_deps ?name ?output branch analyze remote);
      (`Qubes, docteur_solo5 mode extra_deps ?name ?output branch analyze remote);
      ( `Virtio,
        docteur_solo5 mode extra_deps ?name ?output branch analyze remote );
      (`Hvt, docteur_solo5 mode extra_deps ?name ?output branch analyze remote);
      (`Spt, docteur_solo5 mode extra_deps ?name ?output branch analyze remote);
      (`Muen, docteur_solo5 mode extra_deps ?name ?output branch analyze remote);
      ( `Genode,
        docteur_solo5 mode extra_deps ?name ?output branch analyze remote );
    ]
    ~default:(docteur_unix mode extra_deps ?name ?output branch analyze remote)

let chamelon ~program_block_size =
  let runtime_args = Runtime_arg.[ v program_block_size ] in
  let packages = [ package "chamelon" ~sublibs:[ "kv" ] ~min:"0.0.8" ] in
  let connect _ modname = function
    | [ block; program_block_size ] ->
        code ~pos:__POS__
          {ocaml|%s.connect ~program_block_size:%s %s
                 >|= Result.map_error (Fmt.str "%%a" %s.pp_error)
                 >|= Result.fold ~ok:Fun.id ~error:failwith|ocaml}
          modname program_block_size block modname
    | _ -> Misc.connect_err "chameleon" 2
  in
  impl ~packages ~runtime_args ~connect "Kv.Make" (block @-> Kv.rw)

let ccm_block ?nonce_len key =
  let runtime_args = Runtime_arg.[ v key ] in
  let packages = [ package "mirage-block-ccm" ~min:"2.0.0" ~max:"3.0.0" ] in
  let connect _ modname = function
    | [ block; key ] ->
        code ~pos:__POS__
          {ocaml|let key = %s in
                 let key =
                   if String.length key >= 2 && String.(equal "0x" (sub key 0 2)) then
                     String.sub key 2 (String.length key - 2)
                   else
                     key
                 in
                 %s.connect ?nonce_len:%a ~key:(Cstruct.of_hex key) %s|ocaml}
          key modname
          Fmt.(parens (Dump.option int))
          nonce_len block
    | _ -> Misc.connect_err "ccm_block" 2
  in
  impl ~packages ~runtime_args ~connect "Block_ccm.Make" (block @-> block)
