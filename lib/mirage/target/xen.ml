open Functoria

(* We generate an example .xl with common defaults, and a generic
   .xl.in which has @VARIABLES@ which must be substituted by sed
   according to the preferences of the system administrator.
   The common defaults chosen for the .xl file will be based on values
   detected from the build host. We assume that the .xl file will
   mainly be used by developers where build and deployment are on the
   same host. Production users should use the .xl.in and perform the
   appropriate variable substition.
*)

let detected_bridge_name =
  (* Best-effort guess of a bridge name stem to use. Note this
     inspects the build host and will probably be wrong if the
     deployment host is different. *)
  match
    List.fold_left
      (fun sofar x ->
        match sofar with
        (* This is Linux-specific *)
        | None when Sys.file_exists (Fmt.str "/sys/class/net/%s0" x) -> Some x
        | None -> None
        | Some x -> Some x)
      None [ "xenbr"; "br"; "virbr" ]
  with
  | Some x -> x
  | None -> "br"

module Substitutions = struct
  type v =
    | Name
    | Kernel
    | Memory
    | Block of Mirage_impl_block.block_t
    | Network of string

  type t = (v * string) list

  let string_of_v = function
    | Name -> "@NAME@"
    | Kernel -> "@KERNEL@"
    | Memory -> "@MEMORY@"
    | Block b -> Fmt.str "@BLOCK:%s@" b.filename
    | Network n -> Fmt.str "@NETWORK:%s@" n

  let lookup ts v =
    if List.mem_assoc v ts then List.assoc v ts else string_of_v v

  let defaults i =
    let blocks =
      List.map
        (fun b -> (Block b, b.filename))
        (Hashtbl.fold (fun _ v acc -> v :: acc) Mirage_impl_block.all_blocks [])
    and networks =
      List.mapi
        (fun i n -> (Network n, Fmt.str "%s%d" detected_bridge_name i))
        !Mirage_impl_network.all_networks
    in
    [ (Name, Info.name i); (Kernel, Info.name i ^ ".xen"); (Memory, "256") ]
    @ blocks
    @ networks
end

let append fmt s = Fmt.pf fmt (s ^^ "@.")

let configure_main_xl ?substitutions ~ext i =
  let open Substitutions in
  let substitutions =
    match substitutions with Some x -> x | None -> defaults i
  in
  let path = Fpath.(v (Info.name i) + ext) in
  Action.with_output ~path ~purpose:"xl file" (fun fmt ->
      let open Mirage_impl_block in
      append fmt "name = '%s'" (lookup substitutions Name);
      append fmt "kernel = '%s'" (lookup substitutions Kernel);
      append fmt "type = 'pvh'";
      append fmt "memory = %s" (lookup substitutions Memory);
      append fmt "on_crash = 'preserve'";
      append fmt "";
      let blocks =
        List.map
          (fun b ->
            (* We need the Linux version of the block number (this is a
                strange historical artifact) Taken from
                https://github.com/mirage/mirage-block-xen/blob/
                a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
            let rec string_of_int26 x =
              let high, low = ((x / 26) - 1, (x mod 26) + 1) in
              let high' = if high = -1 then "" else string_of_int26 high in
              let low' =
                String.make 1 (char_of_int (low + int_of_char 'a' - 1))
              in
              high' ^ low'
            in
            let vdev = Fmt.str "xvd%s" (string_of_int26 b.number) in
            let path = lookup substitutions (Block b) in
            Fmt.str "'format=raw, vdev=%s, access=rw, target=%s'" vdev path)
          (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks [])
      in
      append fmt "disk = [ %s ]" (String.concat ", " blocks);
      append fmt "";
      let networks =
        List.map
          (fun n -> Fmt.str "'bridge=%s'" (lookup substitutions (Network n)))
          !Mirage_impl_network.all_networks
      in
      append fmt
        "# if your system uses openvswitch then either edit /etc/xen/xl.conf \
         and set";
      append fmt "#     vif.default.script=\"vif-openvswitch\"";
      append fmt
        "# or add \"script=vif-openvswitch,\" before the \"bridge=\" below:";
      append fmt "vif = [ %s ]" (String.concat ", " networks))
