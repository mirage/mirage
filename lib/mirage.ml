(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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


let (|>) a f = f a

let (/) = Filename.concat

let finally f cleanup =
  try
    let res = f () in cleanup (); res
  with exn -> cleanup (); raise exn

let output_kv oc kvs sep =
  List.iter (fun (k,v) -> Printf.fprintf oc "%s %s %s\n" k sep v) kvs

let lines_of_file file =
  let ic = open_in file in
  let lines = ref [] in
  let rec aux () =
    let line =
      try Some (input_line ic)
      with _ -> None in
    match line with
    | None   -> ()
    | Some l ->
      lines := l :: !lines;
      aux () in
  aux ();
  close_in ic;
  List.rev !lines

let strip str =
  let p = ref 0 in
  let l = String.length str in
  let fn = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false in
  while !p < l && fn (String.unsafe_get str !p) do
    incr p;
  done;
  let p = !p in
  let l = ref (l - 1) in
  while !l >= p && fn (String.unsafe_get str !l) do
    decr l;
  done;
  String.sub str p (!l - p + 1)

let cut_at s sep =
  try
    let i = String.index s sep in
    let name = String.sub s 0 i in
    let version = String.sub s (i+1) (String.length s - i - 1) in
    Some (name, version)
  with _ ->
    None

let split s sep =
  let rec aux acc r =
    match cut_at r sep with
    | None       -> List.rev (r :: acc)
    | Some (h,t) -> aux (strip h :: acc) t in
  aux [] s

let key_value line =
  match cut_at line ':' with
  | None       -> None
  | Some (k,v) -> Some (k, strip v)

let filter_map f l =
  let rec loop accu = function
    | []     -> List.rev accu
    | h :: t ->
        match f h with
        | None   -> loop accu t
        | Some x -> loop (x::accu) t in
  loop [] l

let subcommand ~prefix (command, value) =
  let p1 = String.uncapitalize prefix in
  match cut_at command '-' with
  | None      -> None
  | Some(p,n) ->
    let p2 = String.uncapitalize p in
    if p1 = p2 then
      Some (n, value)
    else
      None

let append oc fmt =
  Printf.kprintf (fun str ->
    Printf.fprintf oc "%s\n" str
  ) fmt

let newline oc =
  append oc ""

(* Code duplication with irminsule/alcotest *)
let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let red_s = red "%s"
let green_s = green "%s"
let yellow_s = yellow "%s"
let blue_s = blue "%s"

let with_process_in cmd f =
  let ic = Unix.open_process_in cmd in
  try
    let r = f ic in
    ignore (Unix.close_process_in ic) ; r
  with exn ->
    ignore (Unix.close_process_in ic) ; raise exn

let terminal_columns =
  let split s c =
    Re_str.split (Re_str.regexp (Printf.sprintf "[%c]" c)) s in
  try           (* terminfo *)
    with_process_in "tput cols"
      (fun ic -> int_of_string (input_line ic))
  with _ -> try (* GNU stty *)
      with_process_in "stty size"
        (fun ic ->
           match split (input_line ic) ' ' with
           | [_ ; v] -> int_of_string v
           | _ -> failwith "stty")
    with _ -> try (* shell envvar *)
        int_of_string (Sys.getenv "COLUMNS")
      with _ ->
        80

let line oc ?color c =
  let line = match color with
    | Some `Blue   -> blue_s (String.make terminal_columns c)
    | Some `Yellow -> yellow_s (String.make terminal_columns c)
    | None         -> String.make terminal_columns c in
  Printf.fprintf oc "%s\n%!" line

let indent_left s nb =
  let nb = nb - String.length s in
  if nb <= 0 then
    s
  else
    s ^ String.make nb ' '

let indent_right s nb =
  let nb = nb - String.length s in
  if nb <= 0 then
    s
  else
    String.make nb ' ' ^ s

let left_column () =
  20

let right_column () =
  terminal_columns
  - left_column ()
  + 19

let right s =
  Printf.printf "%s\n%!" (indent_right s (right_column ()))

let left s =
  Printf.printf "%s%!" (indent_left s (left_column ()))

let error fmt =
  Printf.kprintf (fun str ->
      Printf.eprintf "%s %s\n%!"
        (indent_left (red_s "[ERROR]") (left_column ()))
        str;
      exit 1;
  ) fmt

let info fmt =
  Printf.kprintf (fun str ->
      left (green_s "MIRAGE");
      Printf.printf "%s%!\n" str
    ) fmt

let debug fmt =
  Printf.kprintf (fun str ->
      left (yellow_s "DEBUG");
      Printf.printf "%s%!\n" str
    ) fmt

let realdir dir =
  if Sys.file_exists dir && Sys.is_directory dir then (
    let cwd = Sys.getcwd () in
    Sys.chdir dir;
    let d = Sys.getcwd () in
    Sys.chdir cwd;
    d
  ) else
    failwith "realdir"

let realpath file =
  if Sys.file_exists file && Sys.is_directory file then realdir file
  else if Sys.file_exists file
       || Sys.file_exists (Filename.dirname file) then
    realdir (Filename.dirname file) / (Filename.basename file)
  else
    failwith "realpath"

let remove file =
  if Sys.file_exists file then (
    info "+ Removing %s." (realpath file);
    Sys.remove file
  )

let command ?switch fmt =
  Printf.kprintf (fun str ->
    let cmd = match switch with
      | None -> str
      | Some cmp -> Printf.sprintf "opam config exec \"%s\" --switch=%s" str cmp in
    info "+ Executing: %s" cmd;
    match Sys.command cmd with
    | 0 -> ()
    | i -> error "The command %S exited with code %d." cmd i
  ) fmt

let opam cmd ?switch deps =
  let deps_str = String.concat " " deps in
  match switch with
  | None     -> command "opam %s --yes %s" cmd deps_str
  | Some cmp -> command "opam %s --yes %s --switch=%s" cmd deps_str cmp

let in_dir dir f =
  let pwd = Sys.getcwd () in
  let reset () =
    if pwd <> dir then Sys.chdir pwd in
  if pwd <> dir then Sys.chdir dir;
  try let r = f () in reset (); r
  with e -> reset (); raise e

let cmd_exists s =
  Sys.command ("which " ^ s ^ " > /dev/null") = 0

let read_command fmt =
  let open Unix in
  Printf.ksprintf (fun cmd ->
    let () = info "+ Executing: %s" cmd in
    let ic, oc, ec = open_process_full cmd (environment ()) in
    let buf1 = Buffer.create 64
    and buf2 = Buffer.create 64 in
    (try while true do Buffer.add_channel buf1 ic 1 done with End_of_file -> ());
    (try while true do Buffer.add_channel buf2 ec 1 done with End_of_file -> ());
    match close_process_full (ic,oc,ec) with
    | WEXITED 0   -> Buffer.contents buf1
    | WSIGNALED n -> error "process killed by signal %d" n
    | WSTOPPED n  -> error "process stopped by signal %d" n
    | WEXITED r   -> error "command terminated with exit code %d\nstderr: %s" r (Buffer.contents buf2)) fmt

let generated_by_mirage =
  let t = Unix.gettimeofday () in
  let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
                  "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |] in
  let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
  let time = Unix.gmtime t in
  let date =
    Printf.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
      days.(time.Unix.tm_wday) time.Unix.tm_mday
      months.(time.Unix.tm_mon) (time.Unix.tm_year+1900)
      time.Unix.tm_hour time.Unix.tm_min time.Unix.tm_sec in
  Printf.sprintf "Generated by Mirage (%s)." date

let ocaml_version () =
  let version =
    match cut_at Sys.ocaml_version '+' with
    | Some (version, _) -> version
    | None              -> Sys.ocaml_version in
  match split version '.' with
  | major :: minor :: _ ->
    begin
      try int_of_string major, int_of_string minor
      with _ -> 0, 0
    end
  | _ -> 0, 0

module StringSet = struct

  include Set.Make(String)

  let of_list l =
    let s = ref empty in
    List.iter (fun e -> s := add e !s) l;
    !s

end

module StringMap = Map.Make(String)

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]

type main_ml = {
  filename: string;
  oc: out_channel;
  mutable modules: string StringMap.t;
}

module type CONFIGURABLE = sig
  type t
  val name: t -> string
  val packages: t -> mode -> string list
  val libraries: t -> mode -> string list
  val configure: t -> mode -> main_ml -> unit
  val clean: t -> unit
end

module Headers = struct

  let output oc =
    append oc "(* %s *)" generated_by_mirage;
    newline oc

end

let driver_initialisation_error name =
  Printf.sprintf "fail (Mirage_types.V1.Driver_initialisation_error %S)" name

module Io_page = struct

  (** Memory allocation interface. *)

  type t = unit

  let name _ = "io_page"

  let packages _ = function
    | `Unix _ -> ["io-page-unix"]
    | `Xen    -> ["io-page-xen"]

  let libraries t mode =
    packages t mode

  let configure t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then
      d.modules <- StringMap.add name "Io_page" d.modules

  let clean t =
    ()

end

module Clock = struct

  (** Clock operations. *)

  type t = unit

  let name _ = "clock"

  let packages _ mode =
    match mode with
    | `Unix _ -> ["mirage-clock-unix"]
    | `Xen -> ["mirage-clock-xen"]

  let libraries _ mode =
    match mode with
    | `Unix _ -> ["mirage-clock-unix"]
    | `Xen -> ["mirage-clock-xen"]

  let configure t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then (
      d.modules <- StringMap.add name "Clock" d.modules;
      append d.oc "let %s = return_unit" name;
    )

  let clean t =
    ()

end

module KV_RO = struct

  type t = {
    name   : string;
    dirname: string;
  }

  let name t = t.name

  let packages _ _ = [
    "mirage-types";
    "lwt";
    "io-page";
    "cstruct";
    "ocaml-crunch";
  ]

  let libraries _ mode = [
    "mirage-types";
    "lwt";
    "cstruct";
    match mode with
    | `Unix _ -> "io-page-unix"
    | `Xen    -> "io-page-xen"
  ]

  let ml t =
    Printf.sprintf "static_%s.ml" t.name

  let mli t =
    Printf.sprintf "static_%s.mli" t.name

  let configure t mode d =
    if not (StringMap.mem t.name d.modules) then (

      if not (cmd_exists "ocaml-crunch") then
        error "ocaml-crunch not found, stopping.";
      let file = ml t in
      if Sys.file_exists t.dirname then (
        info "Generating %s/%s." (Sys.getcwd ()) file;
        command "ocaml-crunch -o %s %s" file t.dirname
      ) else
        error "The directory %s does not exist." t.dirname;

      let m = "Static_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  Static_%s.connect ()" t.name;
      newline d.oc;
    )

  let clean t =
    remove (ml t);
    remove (mli t)

end

module Console = struct

  type t = unit

  let name _ = "console"

  let packages _ mode =
    match mode with
    | `Unix _ -> ["mirage-console-unix"]
    | `Xen -> ["mirage-console-xen"]

  let libraries _ mode =
    match mode with
    | `Unix _ -> ["mirage-console-unix"]
    | `Xen -> ["mirage-console-xen"]

  let configure t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then (
      d.modules <- StringMap.add name "Console" d.modules;
      append d.oc "let %s = Console.connect \"\"" name;
      newline d.oc
    )

  let clean t =
    ()

end

module Block = struct

  type t = {
    name     : string;
    filename : string;
    read_only: bool;
  }

  let name t = t.name

  let packages _ mode = [
    match mode with
    | `Unix _ -> "mirage-block-unix"
    | `Xen    -> "mirage-block-xen"
  ]

  let libraries _ = function
    | `Unix _ -> ["mirage-block-unix"]
    | `Xen    -> ["mirage-block-xen.front"]

  let configure t mode d =
    if not (StringMap.mem t.name d.modules) then (
      let m = "Block" in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  %s.connect %S" m t.filename;
      newline d.oc
    )

  let clean t =
    ()

end

module Fat = struct

  type t = {
    name : string;
    block: Block.t;
  }

  let name t = t.name

  let packages t mode = [
    "fat";
  ]
    @ Io_page.packages () mode
    @ Block.packages t.block mode

  let libraries t mode = [
    "fat-filesystem";
  ]
    @ Io_page.libraries () mode
    @ Block.libraries t.block mode

  let configure t mode d =
    if not (StringMap.mem t.name d.modules) then (
      Block.configure t.block mode d;
      let m = "Fat_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "module %s = Fat.Fs.Make(%s)(Io_page)"
        m (StringMap.find t.block.Block.name d.modules);
      newline d.oc;
      append d.oc "let %s =" t.name;
      append d.oc " %s >>= function" (Block.name t.block);
      append d.oc " | `Error _ -> %s" (driver_initialisation_error t.name);
      append d.oc " | `Ok dev  -> %s.connect dev" m
    )

  let clean t =
    Block.clean t.block

end

(** {2 Network configuration} *)

module Network = struct

  type t = Tap0 | Custom of string

  let name t =
    "net_" ^ match t with
      | Tap0     -> "tap0"
      | Custom s -> s

  let packages t = function
    | `Unix _ -> [ "mirage-net-unix" ]
    | `Xen    -> [ "mirage-net-xen" ]

  let libraries t mode =
    packages t mode

  let configure t mode d =
    let n = name t in
    if not (StringMap.mem n d.modules) then (
      let m = "Network" in
      d.modules <- StringMap.add n m d.modules;
      newline d.oc;
      append d.oc "let %s =" n;
      append d.oc "  Netif.connect %S" (match t with Tap0 -> "tap0" | Custom s -> s);
      newline d.oc;
    )

  let clean _ =
    ()

end

module IP = struct

  (** IP settings. *)

  type ipv4 = {
    address : Ipaddr.V4.t;
    netmask : Ipaddr.V4.t;
    gateway : Ipaddr.V4.t list;
  }

  type config =
    | DHCP
    | IPv4 of ipv4

  type t = {
    name    : string;
    config  : config;
    networks: Network.t list;
    callback: string option;
  }

  let packages _ = function
    | `Unix `Direct -> ["mirage-net-direct-unix"]
    | `Unix `Socket -> ["mirage-net-socket-unix"]
    | `Xen          -> []

  let libraries t mode =
    packages t mode

  let name t = t.name

  let configure t mode d =
    List.iter (fun n -> Network.configure n mode d) t.networks;
    if not (StringMap.mem t.name d.modules) then (
      let m = "IP_%s" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  let conf = %s in"
        (match t.config with
         | DHCP   -> "`DHCP"
         | IPv4 i ->
           append d.oc "  let i = Ipaddr.V4.of_string_exn in";
           Printf.sprintf "`IPv4 (i %S, i %S, [%s])"
             (Ipaddr.V4.to_string i.address)
             (Ipaddr.V4.to_string i.netmask)
             (String.concat "; "
                (List.map (Printf.sprintf "i %S")
                   (List.map Ipaddr.V4.to_string i.gateway))));
      List.iter (fun n ->
          let name = Network.name n in
          append d.oc "  %s >>= function" name;
          append d.oc "  | `Error _ -> %s" (driver_initialisation_error name);
          append d.oc "  | `Ok %s ->" name;
        ) t.networks;
      append d.oc"  Net.Manager.create [%s] (fun t interface id ->"
        (String.concat "; " (List.map Network.name t.networks));
      append d.oc "    Net.Manager.configure interface conf";
      begin match t.callback with
        | None   -> ()
        | Some c ->
          append d.oc "    >>= fun () ->";
          append d.oc "    %s t interface id" c;
      end;
      append d.oc "  )";
      newline d.oc
    )

  let clean t =
    ()

end

module HTTP = struct

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    static : KV_RO.t option;
  }

  let name t = "http_" ^ string_of_int t.port

  let packages t mode = [
    "cohttp"
  ] @
    match t.static with
    | None   -> []
    | Some s -> KV_RO.packages s mode

  let libraries t mode = [
    "cohttp.mirage";
  ] @
    match t.static with
    | None   -> []
    | Some s -> KV_RO.libraries s mode

  let configure _ =
    failwith "TODO"

  let clean t =
    ()

end

module Driver = struct

  type t =
    | Io_page of Io_page.t
    | Console of Console.t
    | Clock of Clock.t
    | Network of Network.t
    | KV_RO of KV_RO.t
    | Block of Block.t
    | Fat of Fat.t
    | IP of IP.t
    | HTTP of HTTP.t

  let name = function
    | Io_page x -> Io_page.name x
    | Console x -> Console.name x
    | Clock x   -> Clock.name x
    | Network x -> Network.name x
    | KV_RO x   -> KV_RO.name x
    | Block x   -> Block.name x
    | Fat x     -> Fat.name x
    | IP x      -> IP.name x
    | HTTP x    ->  HTTP.name x

  let packages = function
    | Io_page x -> Io_page.packages x
    | Console x -> Console.packages x
    | Clock x   -> Clock.packages x
    | Network x -> Network.packages x
    | KV_RO x   -> KV_RO.packages x
    | Block x   -> Block.packages x
    | Fat x     -> Fat.packages x
    | IP x      -> IP.packages x
    | HTTP x    -> HTTP.packages x

  let libraries = function
    | Io_page x -> Io_page.libraries x
    | Console x -> Console.libraries x
    | Clock x   -> Clock.libraries x
    | Network x -> Network.libraries x
    | KV_RO x   -> KV_RO.libraries x
    | Block x   -> Block.libraries x
    | Fat x     -> Fat.libraries x
    | IP x      -> IP.libraries x
    | HTTP x    -> HTTP.libraries x

  let configure = function
    | Io_page x -> Io_page.configure x
    | Console x -> Console.configure x
    | Clock x   -> Clock.configure x
    | Network x -> Network.configure x
    | KV_RO x   -> KV_RO.configure x
    | Block x   -> Block.configure x
    | Fat x     -> Fat.configure x
    | IP x      -> IP.configure x
    | HTTP x    -> HTTP.configure x

  let clean = function
    | Io_page x -> Io_page.clean x
    | Console x -> Console.clean x
    | Clock x   -> Clock.clean x
    | Network x -> Network.clean x
    | KV_RO x   -> KV_RO.clean x
    | Block x   -> Block.clean x
    | Fat x     -> Fat.clean x
    | IP x      -> IP.clean x
    | HTTP x    -> HTTP.clean x

  let rec map_path fn = function
    | KV_RO x -> KV_RO { x with KV_RO.dirname = fn x.KV_RO.dirname }
    | Block x -> Block { x with Block.filename = fn x.Block.filename }
    | Fat x   ->
      begin match map_path fn (Block x.Fat.block) with
        | Block block -> Fat { x with Fat.block }
        | _ -> assert false
      end
    | x       -> x


  let update_path t root =
    let fn path =
      realpath (Filename.concat root path) in
    map_path fn t

  let io_page = Io_page ()

  let console = Console ()

  let clock = Clock ()

  let tap0 = Network Network.Tap0

  let local_ip network =
    let i s = Ipaddr.V4.of_string_exn s in
    let config = IP.IPv4 {
        IP.address = i "10.0.0.2";
        netmask    = i "255.255.255.0";
        gateway    = [i "10.0.0.1"];
      } in
    IP {
      IP.name  = "ip";
      config;
      callback = None;
      networks = [network]
    }

  let all = ref []

  let all : t list ref =
    ref []

  let reset () =
    all := []

  let register j =
    all := j @ !all

  let registered () =
    !all

end

module Job = struct

  type t = {
    name   : string;
    handler: string;
    params : Driver.t list;
  }

  let count = ref 0

  let create handler params =
    incr count;
    let name = "job" ^ string_of_int !count in
    { name; handler; params }

  let name t =
    t.name

  let fold fn { params } =
    let s = List.fold_left (fun set param ->
        let s = fn param in
        StringSet.union set (StringSet.of_list s)
      ) StringSet.empty params in
    StringSet.elements s

  let iter fn { params } =
    List.iter fn params

  let packages t mode =
    fold (fun d -> Driver.packages d mode) t

  let libraries t mode =
    "mirage.types" :: fold (fun d -> Driver.libraries d mode) t

  let configure t mode d =
    iter (fun p -> Driver.configure p mode d) t;
    newline d.oc;
    let modules = List.map (fun p ->
        let m = StringMap.find (Driver.name p) d.modules in
        Printf.sprintf "(%s)" m
      ) t.params in
    let names = List.map Driver.name t.params in
    let m = String.capitalize t.name in
    append d.oc "module %s = %s%s" m t.handler (String.concat "" modules);
    newline d.oc;
    append d.oc "let %s =" t.name;
    List.iter (fun name ->
        append d.oc "  %s >>= function" name;
        append d.oc "  | `Error _ -> %s" (driver_initialisation_error name);
        append d.oc "  | `Ok %s   ->" name;
      ) names;
    append d.oc "  %s.start %s" m (String.concat " " names);
    newline d.oc

  let clean t =
    iter Driver.clean t

  let all : t list ref =
    ref []

  let reset () =
    Driver.reset ();
    all := []

  let register j =
    all := List.map (fun (n,p) -> create n p) j @ !all

  let registered () =
    !all

  let update_path t root =
    let params = List.map (fun t -> Driver.update_path t root) t.params in
    { t with params }

end

type t = {
  name: string;
  root: string;
  jobs: Job.t list;
  drivers: Driver.t list;
}

let name t = t.name

let main_ml t =
  let filename = t.root / "main.ml" in
  let oc = open_out filename in
  append oc "(* %s *)" generated_by_mirage;
  newline oc;
  append oc "open Lwt";
  newline oc;
  { filename; oc; modules = StringMap.empty; }

let fold extract fn t init =
  let s = List.fold_left (fun set job ->
      let s = fn job in
      StringSet.union set (StringSet.of_list s)
    ) init (extract t) in
  StringSet.elements s

let fold_jobs = fold (fun t -> t.jobs)

let fold_drivers = fold (fun t -> t.drivers)

let ps = ref StringSet.empty

let add_to_opam_packages p =
  ps := StringSet.union (StringSet.of_list p) !ps

let fold_x job_x driver_x t mode =
  let m = match mode with
    | `Unix _ -> "mirage-unix"
    | `Xen    -> "mirage-xen" in
  let jobs = fold_jobs (fun j -> job_x j mode) t !ps in
  let drivers = fold_drivers (fun d -> driver_x d mode) t StringSet.empty in
  let s = StringSet.(add  m (union (of_list jobs) (of_list drivers))) in
  StringSet.elements s

let packages = fold_x Job.packages Driver.packages

let ls = ref StringSet.empty

let add_to_ocamlfind_libraries l =
  ls := StringSet.union !ls (StringSet.of_list l)

let libraries t mode =
  "mirage.types" :: fold_x Job.libraries Driver.libraries t mode

let clean_jobs t =
  List.iter Job.clean t.jobs;
  List.iter Driver.clean t.drivers

let configure_myocamlbuild_ml t mode d =
  let minor, major = ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = t.root / "myocamlbuild.ml" in
    let oc = open_out file in
    append oc "(* %s *)" generated_by_mirage;
    newline oc;
    append oc
      "open Ocamlbuild_pack;;\n\
       open Ocamlbuild_plugin;;\n\
       open Ocaml_compiler;;\n\
       \n\
       let native_link_gen linker =\n\
      \  link_gen \"cmx\" \"cmxa\" !Options.ext_lib [!Options.ext_obj; \"cmi\"] linker;;\n\
       \n\
       let native_output_obj x = native_link_gen ocamlopt_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"native\"++\"output_obj\") x;;\n\
       \n\
       rule \"ocaml: cmx* & o* -> native.o\"\n\
      \  ~tags:[\"ocaml\"; \"native\"; \"output_obj\" ]\n\
      \  ~prod:\"%%.native.o\" ~deps:[\"%%.cmx\"; \"%%.o\"]\n\
      \  (native_output_obj \"%%.cmx\" \"%%.native.o\");;\n\
       \n\
       \n\
       let byte_link_gen = link_gen \"cmo\" \"cma\" \"cma\" [\"cmo\"; \"cmi\"];;\n\
       let byte_output_obj = byte_link_gen ocamlc_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"byte\"++\"output_obj\");;\n\
       \n\
       rule \"ocaml: cmo* -> byte.o\"\n\
      \  ~tags:[\"ocaml\"; \"byte\"; \"link\"; \"output_obj\" ]\n\
       ~prod:\"%%.byte.o\" ~dep:\"%%.cmo\"\n\
      \  (byte_output_obj \"%%.cmo\" \"%%.byte.o\");;";
    close_out oc
  )

let clean_myocamlbuild_ml t =
  remove (t.root / "myocamlbuild.ml")

let configure_makefile t mode d =
  let file = t.root / "Makefile" in
  let libraries =
    match "lwt.syntax" :: libraries t mode with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " (packages t mode) in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "LIBS   = %s" libraries;
  append oc "PKGS   = %s" packages;
  append oc "SYNTAX = -tags \"syntax(camlp4o)\"\n";
  begin match mode with
    | `Xen ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n"
    | `Unix _ ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
  end;
  append oc "BUILD  = ocamlbuild -classic-display -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam";
  newline oc;
  append oc ".PHONY: all prepare clean\n\
             all: build\n\
             \n\
             prepare:\n\
             \t$(OPAM) install $(PKGS)\n\
             \n\
             main.native:\n\
             \t$(BUILD) main.native\n\
             \n\
             main.native.o:\n\
             \t$(BUILD) main.native.o";
  newline oc;
  begin match mode with
    | `Xen ->
      append oc "build: main.native.o";
      let path = read_command "ocamlfind printconf path" in
      let lib = strip path ^ "/mirage-xen" in
      append oc "\tld -d -nostdlib -m elf_x86_64 -T %s/mirage-x86_64.lds %s/x86_64.o \\\n\
                 \t  _build/main.native.o %s/libocaml.a %s/libxen.a \\\n\
                 \t  %s/libxencaml.a %s/libdiet.a %s/libm.a %s/longjmp.o -o mir-main.xen"
        lib lib lib lib lib lib lib lib;
    | `Unix _ ->
      append oc "build: main.native";
      append oc "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "run: build";
  begin match mode with
    | `Xen ->
      append oc "\txl create %s.xl" t.name
    | `Unix _ ->
      append oc "\t$(SUDO) ./mir-%s" t.name
  end;
  append oc "clean:\n\
             \tocamlbuild -clean";
  close_out oc

let clean_makefile t =
  remove (t.root / "Makefile")

let configure_opam t mode d =
  info "Installing OPAM packages.";
  match packages t mode with
  | [] -> ()
  | ps ->
    if cmd_exists "opam" then opam "install" ps
    else error "OPAM is not installed."

let clean_opam t =
  let (++) = StringSet.union in
  let set mode = StringSet.of_list (packages t mode) in
  let packages =
    set (`Unix `Socket) ++ set (`Unix `Direct) ++ set `Xen in
  match StringSet.elements packages with
  | [] -> ()
  | ps ->
    if cmd_exists "opam" then opam "remove" ps
    else error "OPAM is not installed."

let manage_opam = ref true

let manage_opam_packages b =
  manage_opam := b

let configure_main t mode d =
  info "Generating %s" d.filename;
  List.iter (fun j -> Job.configure j mode d) t.jobs;
  List.iter (fun r -> Driver.configure r mode d) t.drivers;
  newline d.oc;
  let jobs = List.map Job.name t.jobs in
  let drivers = List.map Driver.name t.drivers in
  append d.oc "let () =";
  append d.oc "  OS.Main.run (join [%s])" (String.concat "; " (jobs @ drivers))

let clean_main t =
  clean_jobs t;
  remove (t.root / "main.ml")


(* XXX
module XL = struct
  let output name kvs =
    info "+ creating %s" (name ^ ".xl");
    let oc = open_out (name ^ ".xl") in
    finally
      (fun () ->
         output_kv oc (["name", "\"" ^ name ^ "\"";
                        "kernel", "\"mir-" ^ name ^ ".xen\""] @
                         filter_map (subcommand ~prefix:"xl") kvs) "=")
      (fun () -> close_out oc);
end

*)

let configure t mode d =
  info "%d JOBS: %s | %d DRIVERS: %s"
    (List.length t.jobs)
    (String.concat ", " (List.map Job.name t.jobs))
    (List.length t.drivers)
    (String.concat ", " (List.map Driver.name t.drivers));
  in_dir t.root (fun () ->
      if !manage_opam then configure_opam t mode d;
      configure_myocamlbuild_ml t mode d;
      configure_makefile t mode d;
      configure_main t mode d
    )

let uname_s () =
  try
    with_process_in "uname -s"
      (fun ic -> Some (strip (input_line ic)))
  with _ ->
    None

let make () =
  match uname_s () with
  | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
  | _ -> "make"

let build t =
  in_dir t.root (fun () ->
      command "%s build" (make ())
    )

let run t =
  in_dir t.root (fun () ->
      command "%s run" (make ())
    )

let clean t =
  in_dir t.root (fun () ->
      if !manage_opam then clean_opam t;
      clean_myocamlbuild_ml t;
      clean_makefile t;
      clean_main t;
      command "rm -rf %s/_build" t.root;
      command "rm -rf %s/main.native.o %s/main.native %s/mir-main %s/*~"
        t.root t.root t.root t.root;
    )

(* Compile the configuration file and attempt to dynlink it.
 * It is responsible for registering an application via
 * [Mirage_config.register] in order to have an observable
 * side effect to this command. *)
let compile_and_dynlink file =
  info "Compiling and dynlinkg %s" file;
  let root = Filename.dirname file in
  let file = Filename.basename file in
  let file = Dynlink.adapt_filename file in
  command "rm -rf %s/_build/%s.*" root (Filename.chop_extension file);
  command "cd %s && ocamlbuild -use-ocamlfind -pkg mirage %s" root file;
  try Dynlink.loadfile (String.concat "/" [root; "_build"; file])
  with Dynlink.Error err -> error "Error loading config: %s" (Dynlink.error_message err)

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `config.ml` file.
 * If there is more than one, then error out. *)
let scan_conf = function
  | Some f ->
    info "Using the specified config file: %s" (yellow_s f);
    if not (Sys.file_exists f) then error "%s does not exist, stopping." f;
    realpath f
  | None   ->
    let files = Array.to_list (Sys.readdir ".") in
    match List.filter ((=) "config.ml") files with
    | [] -> error "No configuration file ending in .conf found.\n\
                   You'll need to create one to let Mirage know what do do."
    | [f] ->
      info "Using the scanned config file: %s" (yellow_s f);
      realpath f
    | _   -> error "There is more than one config.ml in the current working directory.\n\
                    Please specify one explicitly on the command-line."

let load file =
  let file = scan_conf file in
  let root = realdir (Filename.dirname file) in
  Job.reset ();
  Driver.reset ();
  compile_and_dynlink (root / Filename.basename file);
  let jobs =
    let jobs = Job.registered () in
    List.map (fun j -> Job.update_path j root) jobs in
  let drivers =
    let drivers = Driver.registered () in
    List.map (fun j -> Driver.update_path j root) drivers in
  { name ="main"; root; jobs; drivers }
