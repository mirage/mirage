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

let unopt v = function
  | None -> raise Not_found
  | Some v -> v

let finally f cleanup =
  try
    let res = f () in cleanup (); res
  with exn -> cleanup (); raise exn

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

let error fmt =
  Printf.kprintf (fun str ->
    Printf.eprintf "[mirari] ERROR: %s\n%!" str;
    exit 1;
  ) fmt

let info fmt =
  Printf.kprintf (Printf.printf "[mirari] %s\n%!") fmt

let remove file =
  if Sys.file_exists file then (
    info "+ Removing %s." file;
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

let opam_install ?switch deps =
  let deps_str = String.concat " " deps in
  match switch with
  | None -> command "opam install --yes %s" deps_str
  | Some cmp -> command "opam install --yes %s --switch=%s" deps_str cmp

let in_dir dir f =
  let pwd = Sys.getcwd () in
  let reset () =
    if pwd <> dir then Sys.chdir pwd in
  if pwd <> dir then Sys.chdir dir;
  try let r = f () in reset (); r
  with e -> reset (); raise e

let cmd_exists s =
  Sys.command ("which " ^ s ^ " > /dev/null") = 0

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `.conf` file.
 * If there is more than one, then error out. *)
let scan_conf file =
  match file with
  |Some f ->  info "Using specified config file %s" f; f
  |None -> begin
     let files = Array.to_list (Sys.readdir ".") in
     match List.filter (fun f -> Filename.check_suffix f ".conf") files with
     |[] -> error "No configuration file ending in .conf found.\nYou'll need to create one to let Mirari know what do do."
     |[f] -> info "Using scanned config file %s" f; f
     |_ -> error "There is more than one file ending in .conf in the cwd.\nPlease specify one explicitly on the command-line."
  end

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

let is_target_xen compiler = match compiler with
  | None -> false
  | Some str -> (String.sub str ((String.length str) - 3) 3) = "xen"

let is_target_unix compiler = match compiler with
  | None -> false
  | Some str -> (String.sub str ((String.length str) - 4) 4) = "unix"

(* Headers *)
module Headers = struct

  let output oc =
    append oc "(* Auto-generated by mirari; if you edit by hand you may lose your changes. *)";
    newline oc

end

(* Filesystem *)
module FS = struct

  type fs = {
    name: string;
    path: string;
  }

  type t = {
    dir: string;
    fs : fs list;
  }

  let create ~dir kvs =
    let kvs = filter_map (subcommand ~prefix:"fs") kvs in
    let aux (name, path) = { name; path } in
    { dir; fs = List.map aux kvs }

  let call ?switch t =
    if not (cmd_exists "mir-crunch") then begin
      info "mir-crunch not found, so installing the mirage-fs package.";
      opam_install ?switch ["mirage-fs"];
    end;
    List.iter (fun { name; path} ->
      let path = Printf.sprintf "%s/%s" t.dir path in
      let file = Printf.sprintf "%s/filesystem_%s.ml" t.dir name in
      if Sys.file_exists path then (
        info "Creating %s." file;
        command ?switch "mir-crunch -o %s -name %S %s" file name path
      ) else
      error "The directory %s does not exist." path
    ) t.fs

  let output oc t =
    List.iter (fun { name; _ } ->
      append oc "open Filesystem_%s" name
    ) t.fs;
    newline oc

end

(* IP *)
module IP = struct

  type ipv4 = {
    address: string;
    netmask: string;
    gateway: string;
  }

  type t =
    | DHCP
    | IPv4 of ipv4

  let create kvs =
    let kvs = filter_map (subcommand ~prefix:"ip") kvs in
    let use_dhcp =
      try List.assoc "use-dhcp" kvs = "true"
      with _ -> false in
    if use_dhcp then
      DHCP
    else
      let address =
        try List.assoc "address" kvs
        with _ -> "10.0.0.2" in
      let netmask =
        try List.assoc "netmask" kvs
        with _ -> "255.255.255.0" in
      let gateway =
        try List.assoc "gateway" kvs
        with _ -> "10.0.0.1" in
      IPv4 { address; netmask; gateway }

    let output oc = function
      | DHCP   -> append oc "let ip = `DHCP"
      | IPv4 i ->
        append oc "let get = function Some x -> x | None -> failwith \"Bad IP!\"";
        append oc "let ip = `IPv4 (";
        append oc "  get (Net.Nettypes.ipv4_addr_of_string %S)," i.address;
        append oc "  get (Net.Nettypes.ipv4_addr_of_string %S)," i.netmask;
        append oc "  [get (Net.Nettypes.ipv4_addr_of_string %S)]" i.gateway;
        append oc ")";
        newline oc

end

(* HTTP listening parameters *)
module HTTP = struct

  type http = {
    port   : int;
    address: string option;
  }

  type t = http option

  let create kvs =
    let kvs = filter_map (subcommand ~prefix:"http") kvs in
    if List.mem_assoc "port" kvs &&
       List.mem_assoc "address" kvs then
      let port = List.assoc "port" kvs in
      let address = List.assoc "address" kvs in
      let port =
        try int_of_string port
        with _ -> error "%S s not a valid port number." port in
      let address = match address with
        | "*" -> None
        | a   -> Some a in
      Some { port; address }
    else
      None

  let output oc = function
    | None   -> ()
    | Some t ->
      append oc "let listen_port = %d" t.port;
      begin
        match t.address with
        | None   -> append oc "let listen_address = None"
        | Some a -> append oc "let listen_address = Net.Nettypes.ipv4_addr_of_string %S" a;
      end;
      newline oc

end

(* Main function *)
module Main = struct

  type t =
    | IP of string
    | HTTP of string
    | NOIP of string

  let create kvs =
    let kvs = filter_map (subcommand ~prefix:"main") kvs in
    let is_http = List.mem_assoc "http" kvs in
    let is_ip = List.mem_assoc "ip" kvs in
    let is_noip = List.mem_assoc "noip" kvs in
    match is_http, is_ip, is_noip with
    | false, false, false -> error "No main function is specified. You need to add 'main-{ip,http,noip}: <NAME>'."
    | true , false, false -> HTTP (List.assoc "http" kvs)
    | false, true, false  -> IP (List.assoc "ip" kvs)
    | false, false, true -> NOIP (List.assoc "noip" kvs)
    | _  -> error "Too many main functions."

  let output_http oc main =
    append oc "let main () =";
    append oc "  let spec = Cohttp_lwt_mirage.Server.({";
    append oc "    callback    = %s;" main;
    append oc "    conn_closed = (fun _ () -> ());";
    append oc "  }) in";
    append oc "  Net.Manager.create (fun mgr interface id ->";
    append oc "    Printf.eprintf \"listening to HTTP on port %%d\\\\n\" listen_port;";
    append oc "    Net.Manager.configure interface ip >>";
    append oc "    Cohttp_lwt_mirage.listen mgr (listen_address, listen_port) spec";
    append oc "  )"

  let output_ip oc main =
    append oc "let main () =";
    append oc "  Net.Manager.create (fun mgr interface id ->";
    append oc "    Net.Manager.configure interface ip >>";
    append oc "    %s mgr interface id" main;
    append oc "  )"

  let output_noip oc main = append oc "let main () = %s ()" main

  let output ?compiler oc t =
    begin
      match t with
      | IP main   -> output_ip oc main
      | HTTP main -> output_http oc main
      | NOIP main -> output_noip oc main
    end;
    newline oc;
    append oc "let () = OS.Main.run (Lwt.join [main (); Backend.run ()])"

end

(* .obuild & opam file *)
module Build = struct

  type t = {
    name   : string;
    dir    : string;
    depends: string list;
    packages: string list;
  }

  let get name kvs =
    let kvs = List.filter (fun (k,_) -> k = name) kvs in
    List.fold_left (fun accu (_,v) ->
      split v ',' @ accu
    ) [] kvs

  let create ~dir ~name kvs =
    let depends = get "depends" kvs in
    let packages = get "packages" kvs in
    { name; dir; depends; packages }

  let output ?compiler t =
    let file = Printf.sprintf "%s/main.obuild" t.dir in
    let deps = match t.depends with
      | [] -> ""
      | ds -> ", " ^ String.concat ", " ds in
    let oc = open_out file in
    append oc "obuild-ver: 1";
    append oc "name: %s" t.name;
    append oc "version: 0.0.0";
    newline oc;
    append oc "executable mir-%s" t.name;
    append oc "  main: main.ml";
    append oc "  buildDepends: mirage%s%s" (if is_target_unix compiler then ", fd-send-recv" else "") deps;
    append oc "  pp: camlp4o";
    close_out oc

  let check t =
    if t.packages <> [] && not (cmd_exists "opam") then
      error "OPAM is not installed.";
    if not (cmd_exists "obuild") then
      error "obuild is not installed."

  let prepare ?switch t =
    check t;
    let ps = "obuild" :: t.packages in
    opam_install ?switch ps
end

module Backend = struct

  let output ?compiler dir =
    let file = Printf.sprintf "%s/backend.ml" dir in
    let oc = open_out file in
    if is_target_unix compiler then
        append oc "let (>>=) = Lwt.bind

let run () =
  let backlog = 5 in
  let sockaddr = Unix.ADDR_UNIX (Printf.sprintf \"/tmp/mir-%%d.sock\" (Unix.getpid ())) in
  let sock = Lwt_unix.(socket PF_UNIX SOCK_STREAM 0) in
  let () = Lwt_unix.bind sock sockaddr in
  let () = Lwt_unix.listen sock backlog in

  let rec accept_loop () =
    Lwt_unix.accept sock
    >>= fun (fd, saddr) ->
    Printf.printf \"[backend]: Receiving connection from mirari.\\n%%!\";
    let unix_fd = Lwt_unix.unix_file_descr fd in
    let msgbuf = String.create 11 in
    let nbread, sockaddr, recvfd = Fd_send_recv.recv_fd unix_fd msgbuf 0 11 [] in
    let () = Printf.printf \"[backend]: %%d bytes read, received fd %%d\\n%%!\" nbread (Fd_send_recv.int_of_fd recvfd) in
    let id = (String.trim (String.sub msgbuf 0 10)) in
    let devtype = (if msgbuf.[10] = 'p' then OS.Netif.PCAP else OS.Netif.ETH) in
    OS.Netif.add_vif id devtype recvfd;
    Lwt_unix.(shutdown fd SHUTDOWN_ALL); (* Done, we can shutdown the connection now *)
    accept_loop ()
  in accept_loop ()"
    else
      append oc "let run () = Lwt.return ()"

end

(* A type describing all the configuration of a mirage unikernel *)
type t = {
  file     : string; (* Path of the mirari config file *)
  compiler : string option; (* Compiler version *)
  name     : string; (* Filename of the mirari config file*)
  dir      : string; (* Dirname of the mirari config file *)
  main_ml  : string; (* Name of the entry point function *)
  fs       : FS.t; (* A value describing FS configuration *)
  ip       : IP.t;
  http     : HTTP.t;
  main     : Main.t;
  build    : Build.t;
}

let create ?compiler file =
  let dir     = Filename.dirname file in
  let name    = Filename.chop_extension (Filename.basename file) in
  let lines   = lines_of_file file in
  let kvs     = filter_map key_value lines in
  let compiler = match compiler with
    | Some cmp -> Some cmp
    | None -> try Some (List.assoc "compiler" kvs) with Not_found -> None in
  let main_ml = Printf.sprintf "%s/main.ml" dir in
  let fs      = FS.create ~dir kvs in
  let ip      = IP.create kvs in
  let http    = HTTP.create kvs in
  let main    = Main.create kvs in
  let build   = Build.create ~name ~dir kvs in
  { file; compiler; name; dir; main_ml; fs; ip; http; main; build }


let output_main t =
  let oc = open_out t.main_ml in
  Headers.output oc;
  FS.output oc t.fs;
  IP.output oc t.ip;
  HTTP.output oc t.http;
  Main.output oc t.main;
  close_out oc

let call_crunch_scripts t =
  FS.call ?switch:t.compiler t.fs

let call_configure_scripts t =
  in_dir t.dir (fun () ->
    command ?switch:t.compiler
      "obuild configure %s" (if is_target_xen t.compiler then "--executable-as-obj" else "");
  )

let call_xen_scripts t =
  let obj = Printf.sprintf "%s/dist/build/mir-%s/mir-%s.o" t.dir t.name t.name in
  let target = Printf.sprintf "%s/dist/build/mir-%s/mir-%s.xen" t.dir t.name t.name in
  if Sys.file_exists obj then begin
    let path = match t.compiler with
      | None -> read_command "ocamlfind printconf path"
      | Some cmp -> read_command "opam config exec \"ocamlfind printconf path\" --switch=%s" cmp in
    let lib = strip path ^ "/mirage-xen" in
    command "ld -d -nostdlib -m elf_x86_64 -T %s/mirage-x86_64.lds %s/x86_64.o %s %s/libocaml.a %s/libxen.a \
 %s/libxencaml.a %s/libdiet.a %s/libm.a %s/longjmp.o -o %s"  lib lib obj lib lib lib lib lib lib target;
    command "ln -nfs %s/dist/build/mir-%s/mir-%s.xen mir-%s.xen" t.dir t.name t.name t.name
  end else
    error "xen object file %s not found, cannot continue" obj

let call_build_scripts t =
  let setup = Printf.sprintf "%s/dist/setup" t.dir in
  if Sys.file_exists setup then (
    in_dir t.dir (fun () -> command ?switch:t.compiler "obuild build");
    (* gen_xen.sh *)
    if is_target_xen t.compiler then
      call_xen_scripts t
    else
      command "ln -nfs %s/dist/build/mir-%s/mir-%s mir-%s" t.dir t.name t.name t.name
  ) else
    error "You should run 'mirari configure %s' first." t.file

let configure ?compiler ~no_install file =
  let file = scan_conf file in
  let t = create ?compiler file in
  (* Generate main.ml *)
  info "Generating %s." t.main_ml;
  output_main t;
  (* Generate the .obuild file *)
  Build.output ?compiler t.build;
  (* Generate the Backend module *)
  Backend.output ?compiler t.dir;
  (* install OPAM dependencies *)
  if not no_install then Build.prepare ?switch:t.compiler t.build;
  (* crunch *)
  call_crunch_scripts t;
  (* obuild configure *)
  call_configure_scripts t

let build ?compiler file =
    let file = scan_conf file in
    let t = create ?compiler file in
  (* build *)
  call_build_scripts t

let run ?compiler file =
  let file = scan_conf file in
  let t = create ?compiler file in
  match compiler with
    | None -> Unix.execv ("mir-" ^ t.name) [||] (* unix-socket backend *)
    | Some c when is_target_unix (Some c) ->
    (* unix-direct backend: launch the unikernel, then create a TAP
       interface and pass the fd to the unikernel *)

      let cpid = Unix.fork () in
      if cpid = 0 then (* child code *)
        Unix.execv ("mir-" ^ t.name) [||] (* Launch the unikernel *)
      else
        begin
          try
            info "Creating tap0 interface.";
            (* Force the name to be "tap0" because of MacOSX *)
            let fd, id =
              (try
                 let fd, id = Tuntap.opentap ~devname:"tap0" () in
                 (* TODO: Do not hardcode 10.0.0.1, put it in mirari config file *)
                 let () = Tuntap.set_ipv4 ~devname:"tap0" ~ipv4:"10.0.0.1" () in
                 fd, id
               with Failure m ->
                 Printf.eprintf "[mirari] Tuntap failed with error %s. Remember that %s has to be run as root have the CAP_NET_ADMIN \
 capability in order to be able to run unikernels for the UNIX backend" m Sys.argv.(0);
                 raise (Failure m)) (* Go to cleanup section *)
            in
           let sock = Unix.(socket PF_UNIX SOCK_STREAM 0) in

           let send_fd () =
             let open Unix in
                 sleep 1;
                 info "Connecting to /tmp/mir-%d.sock..." cpid;
                 connect sock (ADDR_UNIX (Printf.sprintf "/tmp/mir-%d.sock" cpid));
                 let nb_sent = Fd_send_recv.send_fd sock "tap0      e" 0 11 [] fd in
                 if nb_sent <> 11 then
                   (error "Sending fd to unikernel failed.")
                 else info "Transmitted fd ok."
             in
             send_fd ();
             let _,_ = Unix.waitpid [] cpid in ()
          with exn ->
            info "Ctrl-C received, killing child and exiting.\n%!";
            Unix.kill cpid 15; (* Send SIGTERM to the unikernel, and then exit ourselves. *)
            raise exn

      end
  | Some c when is_target_xen (Some c)  -> () (* xen backend *)
  | Some c -> raise (Failure "Unsupported compiler")

(* For now, only delete main.{ml,obuild}, the generated symlink and do
   an obuild clean *)
let clean () =
  command "obuild clean";
  command "rm -f main.ml main.obuild mir-* backend.ml filesystem_*.ml"
