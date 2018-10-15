open Functoria
module Name = Functoria_app.Name
module Key = Mirage_key
open Mirage_impl_misc
open Rresult
open Mirage_impl_kv_ro

type block = BLOCK
let block = Type BLOCK
type block_t = { filename: string; number: int }
let all_blocks = Hashtbl.create 7

let make_block_t =
  (* NB: reserve number 0 for the boot disk *)
  let next_number = ref 1 in
  fun filename ->
    let b =
      if Hashtbl.mem all_blocks filename then
        Hashtbl.find all_blocks filename
      else begin
        let number = !next_number in
        incr next_number;
        let b = { filename; number } in
        Hashtbl.add all_blocks filename b;
        b
      end in
    b

let xen_block_packages =
  [ package ~min:"1.5.0" ~sublibs:["front"] "mirage-block-xen" ]

(* this class takes a string rather than an int as `id` to allow the user to
   pass stuff like "/dev/xvdi1", which mirage-block-xen also understands *)
class xenstore_conf id =
  let name = Name.create id ~prefix:"block" in
  object
    inherit base_configurable
    method ty = block
    method name = name
    method module_name = "Block"
    method! packages = Key.pure xen_block_packages
    method! configure i =
      match get_target i with
      | `Qubes | `Xen -> R.ok ()
      | _ -> R.error_msg "XenStore IDs are only valid ways of specifying block \
                          devices when the target is Xen or Qubes."
    method! connect _ s _ =
      Fmt.strf "%s.connect %S" s id
  end

let block_of_xenstore_id id = impl (new xenstore_conf id)

(* calculate the XenStore ID for the nth available block device.
   Taken from https://github.com/mirage/mirage-block-xen/blob/
   a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 . *)
let xenstore_id_of_index number =
        (if number < 16
         then (202 lsl 8) lor (number lsl 4)
         else (1 lsl 28)  lor (number lsl 8))

class block_conf file =
  let name = Name.create file ~prefix:"block" in
  object (self)
    inherit base_configurable
    method ty = block
    method name = name
    method module_name = "Block"
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Xen | `Qubes -> xen_block_packages
      | `Virtio | `Hvt | `Muen -> [ package ~min:"0.3.0" "mirage-block-solo5" ]
      | `Unix | `MacOSX -> [ package ~min:"2.5.0" "mirage-block-unix" ]

    method! configure _ =
      let _block = make_block_t file in
      R.ok ()

    method private connect_name target root =
      match target with
      | `Unix | `MacOSX | `Virtio | `Hvt | `Muen ->
        Fpath.(to_string (root / file)) (* open the file directly *)
      | `Xen | `Qubes ->
        let b = make_block_t file in
        xenstore_id_of_index b.number |> string_of_int

    method! connect i s _ =
      match get_target i with
      | `Muen -> failwith "Block devices not supported on Muen target."
      | `Unix | `MacOSX | `Virtio | `Hvt | `Xen | `Qubes ->
        Fmt.strf "%s.connect %S" s
          (self#connect_name (get_target i) @@ Info.build_dir i)
  end

let block_of_file file = impl (new block_conf file)

class ramdisk_conf rname =
  object
    inherit base_configurable
    method ty = block
    method name = "ramdisk"
    method module_name = "Ramdisk"
    method! packages =
      Key.pure [ package "mirage-block-ramdisk" ]

    method! connect _i modname _names =
      Fmt.strf "%s.connect ~name:%S" modname rname
  end


let ramdisk rname = impl (new ramdisk_conf rname)

let generic_block ?group ?(key = Key.value @@ Key.block ?group ()) name =
  match_impl key [
    `XenstoreId, block_of_xenstore_id name;
    `BlockFile, block_of_file name;
    `Ramdisk, ramdisk name;
  ] ~default:(ramdisk name)

let tar_block dir =
  let name = Name.create ("tar_block" ^ dir) ~prefix:"tar_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super
    method! build i =
      Bos.OS.Cmd.run Bos.Cmd.(v "tar" % "-cvf" % block_file % dir) >>= fun () ->
      super#build i
  end

let archive_conf = impl @@ object
    inherit base_configurable
    method ty = block @-> kv_ro
    method name = "archive"
    method module_name = "Tar_mirage.Make_KV_RO"
    method! packages =
      Key.pure [ package ~min:"0.8.0" "tar-mirage" ]
    method! connect _ modname = function
      | [ block ] -> Fmt.strf "%s.connect %s" modname block
      | _ -> failwith (connect_err "archive" 1)
  end

let archive block = archive_conf $ block
let archive_of_files ?(dir=".") () = archive @@ tar_block dir
