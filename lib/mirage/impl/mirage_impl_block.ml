open Functoria
open Mirage_impl_misc
open Mirage_impl_kv
open Mirage_impl_pclock
module Key = Mirage_key

type block = BLOCK

let block = Type.v BLOCK

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
    match get_target i with
    | `Qubes | `Xen -> Action.ok ()
    | _ ->
        failwith
          "XenStore IDs are only valid ways of specifying block devices when \
           the target is Xen or Qubes."
  in
  let connect _ impl_name _ = Fmt.str "%s.connect %S" impl_name id in
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
    | #Mirage_key.mode_unix -> file (* open the file directly *)
    | #Mirage_key.mode_xen ->
        let b = make_block_t file in
        xenstore_id_of_index b.number |> string_of_int
    | #Mirage_key.mode_solo5 ->
        (* XXX For now, on Solo5, just pass the "file" name through directly as
         * the Solo5 block device name *)
        file
  in
  let packages_v =
    Key.match_ Key.(value target) @@ function
    | #Mirage_key.mode_xen -> xen_block_packages
    | #Mirage_key.mode_solo5 ->
        [ package ~min:"0.8.0" ~max:"0.9.0" "mirage-block-solo5" ]
    | #Mirage_key.mode_unix ->
        [ package ~min:"2.12.0" ~max:"3.0.0" "mirage-block-unix" ]
  in
  let configure _ =
    let (_ : block_t) = make_block_t file in
    Action.ok ()
  in
  let connect i s _ =
    match get_target i with
    | `Muen -> failwith "Block devices not supported on Muen target."
    | _ -> Fmt.str "%s.connect %S" s (connect_name (get_target i))
  in
  Device.v ~configure ~packages_v ~connect "Block" block

let block_of_file file = of_device (block_conf file)

let ramdisk rname =
  let packages = [ package "mirage-block-ramdisk" ] in
  let connect _ m _ = Fmt.str "%s.connect ~name:%S" m rname in
  impl ~connect ~packages "Ramdisk" block

let generic_block ?group ?(key = Key.value @@ Key.block ?group ()) name =
  match_impl key
    [
      (`XenstoreId, block_of_xenstore_id name);
      (`BlockFile, block_of_file name);
      (`Ramdisk, ramdisk name);
    ]
    ~default:(ramdisk name)

let tar_kv_ro_conf =
  let packages = [ package ~min:"1.0.0" ~max:"3.0.0" "tar-mirage" ] in
  let connect _ modname = function
    | [ block ] -> Fmt.str "%s.connect %s" modname block
    | _ -> failwith (connect_err "tar_kv_ro" 1)
  in
  impl ~packages ~connect "Tar_mirage.Make_KV_RO" (block @-> Mirage_impl_kv.ro)

let tar_kv_rw_conf =
  let packages = [ package ~min:"2.2.0" ~max:"3.0.0" "tar-mirage" ] in
  let connect _ modname = function
    | [ _pclock; block ] -> Fmt.str "%s.connect %s" modname block
    | _ -> failwith (connect_err "tar_kv_rw" 2)
  in
  impl ~packages ~connect "Tar_mirage.Make_KV_RW"
    (pclock @-> block @-> Mirage_impl_kv.rw)

let tar_kv_ro block = tar_kv_ro_conf $ block
let tar_kv_rw pclock block = tar_kv_rw_conf $ pclock $ block
let archive = tar_kv_ro

let fat_conf =
  let packages = [ package ~min:"0.15.0" ~max:"0.16.0" "fat-filesystem" ] in
  let connect _ modname = function
    | [ block ] -> Fmt.str "%s.connect %s" modname block
    | _ -> failwith (connect_err "fat" 1)
  in
  impl ~packages ~connect "Fat.KV_RO" (block @-> Mirage_impl_kv.ro)

let fat_ro block = fat_conf $ block

type mode = [ `Fast | `Light ]

let pp_mode ppf = function
  | `Fast -> Fmt.string ppf "Fast"
  | `Light -> Fmt.string ppf "Light"

let pp_branch ppf = function
  | None -> ()
  | Some branch -> Fmt.pf ppf " -b %s" branch

let docteur_unix (mode : mode) extra_deps disk branch analyze remote =
  let dune info =
    let ctx = Info.context info in
    let disk = Key.get ctx disk in
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
        disk
        Fmt.(list ~sep:nop (const string " " ++ string))
        extra_deps source_tree remote pp_branch branch disk
    in
    [ dune ]
  in
  let install info =
    let ctx = Info.context info in
    let disk = Fpath.v (Key.get ctx disk) in
    Install.v ~etc:[ disk ] ()
  in
  let configure info =
    let ctx = Info.context info in
    let disk = Key.get ctx disk in
    let (_ : block_t) = make_block_t disk in
    Action.ok ()
  in
  let connect _info modname _ =
    Fmt.str
      {ocaml|let ( <.> ) f g = fun x -> f (g x) in
             let f = Rresult.R.(failwith_error_msg <.> reword_error (msgf "%%a" %s.pp_error)) in
             Lwt.map f (%s.connect ~analyze:%a %a)|ocaml}
      modname modname Key.serialize_call (Key.v analyze) Key.serialize_call
      (Key.v disk)
  in
  let keys = [ Key.v disk; Key.v analyze ] in
  let packages = [ package "docteur-unix" ~min:"0.0.6" ] in
  impl ~keys ~packages ~dune ~install ~configure ~connect
    (Fmt.str "Docteur_unix.%a" pp_mode mode)
    ro

let docteur_solo5 (mode : mode) extra_deps disk branch analyze remote =
  let dune info =
    let ctx = Info.context info in
    let disk = Key.get ctx disk in
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
        disk
        Fmt.(list ~sep:nop (const string " " ++ string))
        extra_deps source_tree remote pp_branch branch disk
    in
    [ dune ]
  in
  let install info =
    let ctx = Info.context info in
    let disk = Fpath.v (Key.get ctx disk) in
    Install.v ~etc:[ disk ] ()
  in
  let configure info =
    let ctx = Info.context info in
    let disk = Key.get ctx disk in
    let (_ : block_t) = make_block_t disk in
    Action.ok ()
  in
  let connect _info modname _ =
    Fmt.str
      {ocaml|let ( <.> ) f g = fun x -> f (g x) in
             let f = Rresult.R.(failwith_error_msg <.> reword_error (msgf "%%a" %s.pp_error)) in
             Lwt.map f (%s.connect ~analyze:%a %a)|ocaml}
      modname modname Key.serialize_call (Key.v analyze) Key.serialize_call
      (Key.v disk)
  in
  let keys = [ Key.v disk; Key.v analyze ] in
  let packages = [ package "docteur-solo5" ~min:"0.0.6" ] in
  impl ~keys ~packages ~dune ~install ~configure ~connect
    (Fmt.str "Docteur_solo5.%a" pp_mode mode)
    ro

let disk =
  let doc =
    Key.Arg.info
      ~doc:
        "Name of the docteur disk (for Solo5 targets, the name must contains \
         only alpanumeric characters)."
      [ "disk" ]
  in
  Key.(create "disk" Arg.(opt ~stage:`Configure string "disk" doc))

let analyze =
  let doc =
    Key.Arg.info ~doc:"Analyze at the boot time the given docteur disk."
      [ "analyze" ]
  in
  Key.(create "analyze" Arg.(opt bool true doc))

let docteur ?(mode = `Fast) ?(disk = disk) ?(analyze = analyze) ?branch
    ?(extra_deps = []) remote =
  match_impl
    Key.(value target)
    [
      (`Xen, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Qubes, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Virtio, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Hvt, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Spt, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Muen, docteur_solo5 mode extra_deps disk branch analyze remote);
      (`Genode, docteur_solo5 mode extra_deps disk branch analyze remote);
    ]
    ~default:(docteur_unix mode extra_deps disk branch analyze remote)

let chamelon ~program_block_size =
  let keys = [ Key.v program_block_size ] in
  let packages = [ package "chamelon" ~sublibs:[ "kv" ] ~min:"0.0.8" ] in
  let connect _ modname = function
    | [ block; _ ] ->
        Fmt.str
          {ocaml|%s.connect ~program_block_size:%a %s
                 >|= Result.map_error (Fmt.str "%%a" %s.pp_error)
                 >|= Result.fold ~ok:Fun.id ~error:failwith|ocaml}
          modname Key.serialize_call (Key.v program_block_size) block modname
    | _ -> assert false
  in
  impl ~packages ~keys ~connect "Kv.Make"
    (block @-> pclock @-> Mirage_impl_kv.rw)

let ccm_block ?nonce_len key =
  let keys = [ Key.v key ] in
  let packages =
    [ package "mirage-block-ccm" ~min:"2.0.0" ~max:"3.0.0"; package "astring" ]
  in
  let connect _ modname = function
    | [ block ] ->
        Fmt.str
          {ocaml|let key = %a in
                 let key = match Astring.String.cut ~sep:"0x" key with
                 | Some ("", key) -> key
                 | _ -> key in
               %s.connect ?nonce_len:%a ~key:(Cstruct.of_hex key) %s|ocaml}
          Key.serialize_call (Key.v key) modname
          Fmt.(parens (Dump.option int))
          nonce_len block
    | _ -> assert false
  in
  impl ~packages ~keys ~connect "Block_ccm.Make" (block @-> block)
