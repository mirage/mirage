open Astring
open Functoria_app.Codegen

let rec string_of_int26 x =
  let high, low = x / 26 - 1, x mod 26 + 1 in
  let high' = if high = -1 then "" else string_of_int26 high in
  let low' =
    String.v ~len:1
      (fun _ -> char_of_int (low + (int_of_char 'a') - 1))
  in
  high' ^ low'

(* We need the Linux version of the block number (this is a
   strange historical artifact) Taken from
   https://github.com/mirage/mirage-block-xen/blob/
   a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
let vdev number =
  Fmt.strf "xvd%s" (string_of_int26 number)

let output_main_xl fmt ~name ~kernel ~memory ~blocks ~networks =
  let block_strings =
    List.map
      (fun (number, path) ->
        Fmt.strf "'format=raw, vdev=%s, access=rw, target=%s'" (vdev number) path)
      blocks
  in
  let network_strings =
    List.map
    (fun n -> Fmt.strf "'bridge=%s'" n)
    networks
  in
  append fmt "# %s" (generated_header ()) ;
  newline fmt;
  append fmt "name = '%s'" name;
  append fmt "kernel = '%s'" kernel;
  append fmt "builder = 'linux'";
  append fmt "memory = %s" memory;
  append fmt "on_crash = 'preserve'";
  newline fmt;
  append fmt "disk = [ %s ]" (String.concat ~sep:", " block_strings);
  newline fmt;
  append fmt "# if your system uses openvswitch then either edit \
              /etc/xen/xl.conf and set";
  append fmt "#     vif.default.script=\"vif-openvswitch\"";
  append fmt "# or add \"script=vif-openvswitch,\" before the \"bridge=\" \
              below:";
  append fmt "vif = [ %s ]" (String.concat ~sep:", " network_strings);
