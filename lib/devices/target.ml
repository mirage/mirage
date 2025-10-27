module Dune = Functoria.Dune
module Info = Functoria.Info
module Install = Functoria.Install
module Action = Functoria.Action
open Functoria.DSL

(** A Mirage target: target consists in multiple backends grouped together. *)
module type TARGET = sig
  type t
  (** The type representing a specific backend in a target. *)

  val cast : Key.mode -> t
  (** Ensures the mode is a backend supported by this target. *)

  val dune : Info.t -> Dune.stanza list
  (** Dune rules to build the unikernel *)

  val out : Info.t -> string
  (** Name of the output file (with extension) for this target *)

  val configure : Info.t -> unit Action.t
  (** Configure-time actions. *)

  val build_context : ?build_dir:Fpath.t -> Info.t -> Dune.stanza list
  (** Generate build context configuration *)

  val context_name : Info.t -> string
  (** Dune context *)

  val packages : t -> package list
  (** The required packages to support this backend. *)

  val install : Info.t -> Install.t
  (** [install i] returns which files are installed in context [i]. *)
end

module Unix = struct
  type t = [ `Unix | `MacOSX ]

  let cast = function #t as t -> t | _ -> invalid_arg "not a unix target."
  let packages _ = [ Functoria.package ~min:"5.0.0" ~max:"6.0.0" "mirage-unix" ]

  (*Mirage unix is built on the host build context.*)
  let build_context ?build_dir:_ _ = []
  let context_name _ = "default"
  let configure _ = Action.ok ()
  let main i = Fpath.(base (rem_ext (Info.main i)))

  let public_name i =
    match Info.output i with None -> Info.name i | Some o -> o

  let flags =
    (* Disable "70 [missing-mli] Missing interface file." as we are only
       generating .ml files currently. *)
    [ ":standard"; "-w"; "-70" ]
    @ if Misc.terminal () then [ "-color"; "always" ] else []

  let out = public_name

  let dune i =
    let libraries = Info.libraries i in
    let public_name = public_name i in
    let main = Fpath.to_string (main i) in
    let pp_list f = Dune.compact_list f in
    let dune =
      Dune.stanzaf
        {|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "default"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))

(executable
 (name %s)
 (libraries %a)
 (link_flags (-thread))
 (modules (:standard \ %a))
 (flags %a)
 (enabled_if (= %%{context_name} "default"))
)
|}
        public_name main main main (pp_list "libraries") libraries Fpath.pp
        (Fpath.rem_ext (Fpath.base (Info.config_file i)))
        (pp_list "flags") flags
    in
    [ dune ]

  let install i =
    let public_name = public_name i in
    Install.v ~bin:[ Fpath.(v public_name, v public_name) ] ()
end

module Xen = struct
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
      | Block of Block.block_t
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
          (Hashtbl.fold (fun _ v acc -> v :: acc) Block.all_blocks [])
      and networks =
        List.mapi
          (fun i n -> (Network n, Fmt.str "%s%d" detected_bridge_name i))
          !Network.all_networks
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
        let open Block in
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
            !Network.all_networks
        in
        append fmt
          "# if your system uses openvswitch then either edit /etc/xen/xl.conf \
           and set";
        append fmt "#     vif.default.script=\"vif-openvswitch\"";
        append fmt
          "# or add \"script=vif-openvswitch,\" before the \"bridge=\" below:";
        append fmt "vif = [ %s ]" (String.concat ", " networks))
end

module Solo5 = struct
  open Action.Syntax

  let solo5_manifest_path = Fpath.v "manifest.json"

  type solo5_target = [ `Virtio | `Muen | `Hvt | `Genode | `Spt ]
  type xen_target = [ `Xen | `Qubes ]
  type t = [ solo5_target | xen_target ]

  let cast = function #t as t -> t | _ -> invalid_arg "not a solo5 target."

  let build_packages =
    [
      Functoria.package ~min:"0.8.2" ~max:"2.0.0" ~scope:`Switch ~build:true
        "ocaml-solo5";
      Functoria.package ~min:"0.7.5" ~max:"0.11.0" ~scope:`Switch ~build:true
        "solo5";
    ]

  let runtime_packages target =
    match target with
    | #solo5_target ->
        [ Functoria.package ~min:"0.10.0" ~max:"0.11.0" "mirage-solo5" ]
    | #xen_target ->
        [ Functoria.package ~min:"9.0.0" ~max:"10.0.0" "mirage-xen" ]

  let packages target = build_packages @ runtime_packages target
  let context_name _i = "solo5"

  (* OCaml solo5 build context. *)
  let build_context ?build_dir:_ i =
    let build_context =
      Dune.stanzaf
        {|
  (context (default
  (name %s)
  (host default)
  (toolchain solo5)
  (merlin)
  (disable_dynamically_linked_foreign_archives true)
  ))
  |}
        (context_name i)
    in
    [ build_context ]

  (* Configure step *)
  let generate_manifest_json with_devices () =
    let networks = List.map (fun n -> (n, `Network)) !Network.all_networks in
    let blocks =
      Hashtbl.fold (fun k _v acc -> (k, `Block) :: acc) Block.all_blocks []
    in
    let to_string (name, typ) =
      Fmt.str {json|{ "name": %S, "type": %S }|json} name
        (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC")
    in
    let devices =
      if with_devices then List.map to_string (networks @ blocks) else []
    in
    let s = String.concat ", " devices in
    let* () =
      Action.with_output ~path:solo5_manifest_path
        ~purpose:"Solo5 application manifest file" (fun fmt ->
          Fmt.pf fmt
            {|{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [ %s ]
}
|}
            s)
    in
    Action.write_file (Fpath.v "manifest.ml") ""

  let configure i =
    let name = Info.name i in
    let target = Info.get i Key.target in
    let* () =
      match target with
      | #solo5_target -> generate_manifest_json true ()
      | #xen_target -> generate_manifest_json false ()
      | _ -> assert false
    in
    match target with
    | `Xen ->
        let* () = Xen.configure_main_xl ~ext:"xl" i in
        let* () = Xen.configure_main_xl ~substitutions:[] ~ext:"xl.in" i in
        Libvirt.configure_main ~name
    | `Virtio -> Libvirt.configure_virtio ~name
    | _ -> Action.ok ()

  (* Build *)

  let ext = function
    | `Virtio -> ".virtio"
    | `Muen -> ".muen"
    | `Hvt -> ".hvt"
    | `Genode -> ".genode"
    | `Spt -> ".spt"
    | `Xen | `Qubes -> ".xen"
    | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

  let main i = Fpath.(base (rem_ext (Info.main i)))

  let out i =
    let target = Info.get i Key.target in
    let public_name =
      match Info.output i with None -> Info.name i | Some o -> o
    in
    public_name ^ ext target

  let rename i =
    let out = out i in
    let main = Fpath.to_string (main i) in
    Dune.stanzaf
      {|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "%s"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))
|}
      out (context_name i) main main

  let manifest _i =
    Dune.stanzaf
      {|
(rule
 (targets manifest.c)
 (deps manifest.json)
 (action
  (run solo5-elftool gen-manifest manifest.json manifest.c)))
|}

  let solo5_abi = function
    | #Key.mode_unix | #Key.mode_unikraft -> assert false
    | #Key.mode_xen -> "xen"
    | `Virtio -> "virtio"
    | `Hvt -> "hvt"
    | `Muen -> "muen"
    | `Genode -> "genode"
    | `Spt -> "spt"

  let flags =
    (* Disable "70 [missing-mli] Missing interface file." as we are only
       generating .ml files currently. *)
    [ ":standard"; "-w"; "-70" ]
    @ if Misc.terminal () then [ "-color"; "always" ] else []

  let main i =
    let libraries = Info.libraries i in
    let main = Fpath.to_string (main i) in
    let target = Info.get i Key.target in
    let pp_list f = Dune.compact_list f in
    Dune.stanzaf
      {|
(executable
 (enabled_if (= %%{context_name} "%s"))
 (name %s)
 (modes (native exe))
 (libraries %a)
 (link_flags %a -cclib "-z solo5-abi=%s")
 (modules (:standard \ %a manifest))
 (foreign_stubs (language c) (names manifest))
)
|}
      (context_name i) main (pp_list "libraries") libraries
      (pp_list "link_flags") flags (solo5_abi target) Fpath.pp
      (Fpath.rem_ext (Fpath.base (Info.config_file i)))

  let subdir name s = Dune.stanzaf "(subdir %s\n %a)\n" name Dune.pp (Dune.v s)
  let dune i = [ main i; manifest i; rename i ]

  let install i =
    let target = Info.get i Key.target in
    let name = Info.name i in
    let out = out i in
    let open Fpath in
    let additional_artifacts =
      match target with
      | `Xen -> [ v (name ^ ".xl"); v (name ^ ".xl.in") ]
      | _ -> []
    in
    Install.v ~bin:[ (v out, v out) ] ~etc:additional_artifacts ()
end

module Unikraft = struct
  type t = [ `Firecracker | `QEMU ]

  let configure _ = Action.ok ()
  let cast = function #t as t -> t | _ -> invalid_arg "not a Unikraft target."

  let build_packages =
    [
      Functoria.package ~min:"1.0.0" ~max:"2.0.0" ~scope:`Switch ~build:true
        "ocaml-unikraft";
      Functoria.package ~min:"1.0.0" ~max:"2.0.0" "mirage-unikraft";
    ]

  let backend_packages target =
    match target with
    | `Firecracker ->
        [
          Functoria.package ~scope:`Switch ~build:true
            "ocaml-unikraft-backend-firecracker";
        ]
    | `QEMU ->
        [
          Functoria.package ~scope:`Switch ~build:true
            "ocaml-unikraft-backend-qemu";
        ]

  let packages target = build_packages @ backend_packages target
  let context_name _ = "unikraft"

  let unikraft_abi = function
    | #Key.mode_unix | #Key.mode_solo5 | #Key.mode_xen -> assert false
    | `Firecracker -> "firecracker"
    | `QEMU -> "qemu"

  let build_context ?build_dir:_ i =
    let target = Info.get i Key.target in
    let build_context =
      Dune.stanzaf
        {|
(context
 (default
  (name %s)
  (host default)
  (toolchain unikraft)
  (env
   (_
    (flags :standard -cclib "-z unikraft-backend=%s")
    (c_flags :standard -z unikraft-backend=%s)))
  (merlin)
  (disable_dynamically_linked_foreign_archives true)))
|}
        (context_name i) (unikraft_abi target) (unikraft_abi target)
    in
    [ build_context ]

  let ext = function
    | `Firecracker -> ".fc"
    | `QEMU -> ".qemu"
    | _ -> invalid_arg "Unikraft bindings only defined for Unikraft targets"

  let main i = Fpath.(base (rem_ext (Info.main i)))

  let out i =
    let target = Info.get i Key.target in
    let public_name =
      match Info.output i with None -> Info.name i | Some o -> o
    in
    public_name ^ ext target

  let rename i =
    let out = out i in
    let main = Fpath.to_string (main i) in
    Dune.stanzaf
      {|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "%s"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))
|}
      out (context_name i) main main

  let flags =
    (* Disable "70 [missing-mli] Missing interface file." as we are only
       generating .ml files currently. *)
    [ ":standard"; "-w"; "-70" ]
    @ if Misc.terminal () then [ "-color"; "always" ] else []

  let main i =
    let libraries = Info.libraries i in
    let main = Fpath.to_string (main i) in
    let pp_list f = Dune.compact_list f in
    Dune.stanzaf
      {|
(executable
 (enabled_if
  (= %%{context_name} "%s"))
 (name %s)
 (modes
  (native exe))
 (libraries %a)
 (link_flags %a))
|}
      (context_name i) main (pp_list "libraries") libraries
      (pp_list "link_flags") flags

  let dune i = [ main i; rename i ]

  let out i =
    let target = Info.get i Key.target in
    let public_name =
      match Info.output i with None -> Info.name i | Some o -> o
    in
    public_name ^ ext target

  let install i =
    let out = out i in
    let open Fpath in
    Install.v ~bin:[ (v out, v out) ] ()
end

let choose : Key.mode -> (module TARGET) = function
  | #Solo5.t -> (module Solo5)
  | #Unix.t -> (module Unix)
  | #Unikraft.t -> (module Unikraft)

let dune i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.dune i

let output_message = ref true

let configure i =
  let open Action.Infix in
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.configure i >|= fun () ->
  if !output_message then (
    output_message := false;
    Logs.app (fun m ->
        m
          "Successfully configured the unikernel. Now run 'make' (or more \
           fine-grained steps: 'make all', 'make depends', or 'make lock')."))

let build_context ?build_dir i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.build_context ?build_dir i

let context_name i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.context_name i

let out i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.out i

let packages target =
  let (module Target) = choose target in
  Target.(packages (cast target))

let install i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.install i
