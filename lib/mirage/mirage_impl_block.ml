open Functoria
open Mirage_impl_misc
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
  [ package ~min:"1.7.0" ~max:"2.0.0" ~sublibs:[ "front" ] "mirage-block-xen" ]

(* this function takes a string rather than an int as `id` to allow
   the user to pass stuff like "/dev/xvdi1", which mirage-block-xen
   also understands *)
let xenstore_conf id =
  let build i =
    match get_target i with
    | `Qubes | `Xen -> Action.ok ()
    | _ ->
        failwith
          "XenStore IDs are only valid ways of specifying block devices when \
           the target is Xen or Qubes."
  in
  let connect _ impl_name _ = Fmt.strf "%s.connect %S" impl_name id in
  impl ~build ~connect ~packages:xen_block_packages "Block" block

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
        [ package ~min:"0.6.1" ~max:"0.7.0" "mirage-block-solo5" ]
    | #Mirage_key.mode_unix ->
        [ package ~min:"2.12.0" ~max:"3.0.0" "mirage-block-unix" ]
  in
  let build _ =
    let (_ : block_t) = make_block_t file in
    Action.ok ()
  in
  let connect i s _ =
    match get_target i with
    | `Muen -> failwith "Block devices not supported on Muen target."
    | _ -> Fmt.strf "%s.connect %S" s (connect_name (get_target i))
  in
  Device.v ~build ~packages_v ~connect "Block" block

let block_of_file file = of_device (block_conf file)

let ramdisk rname =
  let packages = [ package "mirage-block-ramdisk" ] in
  let connect _ m _ = Fmt.strf "%s.connect ~name:%S" m rname in
  impl ~connect ~packages "Ramdisk" block

let generic_block ?group ?(key = Key.value @@ Key.block ?group ()) name =
  match_impl key
    [
      (`XenstoreId, block_of_xenstore_id name);
      (`BlockFile, block_of_file name);
      (`Ramdisk, ramdisk name);
    ]
    ~default:(ramdisk name)

let count =
  let i = ref 0 in
  fun () ->
    incr i;
    !i

let tar_block dir =
  let name = "tar_block" ^ string_of_int (count ()) in
  let block_file = name ^ ".img" in
  let files _ = [ Fpath.v block_file ] in
  let pre_build _ =
    Action.run_cmd Bos.Cmd.(v "tar" % "-cvf" % block_file % dir)
  in
  of_device @@ Device.extend ~pre_build ~files (block_conf block_file)

let archive_conf =
  let packages = [ package ~min:"1.0.0" ~max:"2.0.0" "tar-mirage" ] in
  let connect _ modname = function
    | [ block ] -> Fmt.strf "%s.connect %s" modname block
    | _ -> failwith (connect_err "archive" 1)
  in
  impl ~packages ~connect "Tar_mirage.Make_KV_RO" (block @-> Mirage_impl_kv.ro)

let archive block = archive_conf $ block

let archive_of_files ?(dir = ".") () = archive @@ tar_block dir
