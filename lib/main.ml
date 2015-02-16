(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Cmdliner

let global_option_section = "COMMON OPTIONS"
let help_sections = [
  `S global_option_section;
  `P "These options are common to all commands.";
]

(* Helpers *)
let mk_flag ?section flags doc =
  let doc = Arg.info ?docs:section ~doc flags in
  Arg.(value & flag & doc)

let term_info title ~doc ~man =
  let man = man @ help_sections in
  Term.info ~sdocs:global_option_section ~doc ~man title

let arg_list name doc conv =
  let doc = Arg.info ~docv:name ~doc [] in
  Arg.(value & pos_all conv [] & doc)

let no_opam =
  mk_flag ["no-opam"] "Do not manage the OPAM configuration.  This will result in dependent libraries not being automatically installed during the configuration phase."
let xen =
  mk_flag ["xen"] "Generate a Xen unikernel. Do not use in conjunction with --unix."
let unix =
  mk_flag ["unix"] "Use Unix backend. Do not use in conjunction with --xen.  On MacOS X, this will use platform-specific code to be generated.  To force pure Unix mode on MacOS X, set the $(b,-t) flag to $(i,unix) instead."

let no_opam_version_check =
  mk_flag ["no-opam-version-check"] "Bypass the check of opam's version."

let target =
  let doc = "Target platform to compile the unikernel for.  Valid values are: $(i,xen), $(i,unix), $(i,macosx).  There are short forms available via $(b,--xen) and $(b,--unix) as well." in
  let e = Arg.enum [ "unix", `Unix; "macosx", `MacOSX; "xen", `Xen ] in
  Arg.(value & opt (some e) None & info ["t";"target"] ~docv:"TARGET" ~doc)

(* Select the operating mode from command line flags *)
let mode unix xen target =
  let default_unix =
    match Mirage_misc.uname_s () with
    | Some "Darwin" -> begin
      (* Only use MacOS-specific functionality from Yosemite upwards *)
      let is_yosemite_or_higher =
        match Mirage_misc.uname_r () with
        | None -> false
        | Some vs ->
           match Mirage_misc.split vs '.' with
           | [] -> false
           | hd::_ -> begin
              let v = try int_of_string hd with _ -> 0 in
              v >= 14
           end
      in
      if is_yosemite_or_higher then `MacOSX else `Unix
    end
    | _ -> `Unix
  in
  (** Specifying --target takes priority over other flags *)
  match target with
  | Some t -> t
  | None -> begin
    (** For legacy reasons, Unix maps to either Unix or MacOS X *)
    match xen, unix with
    | true , true  -> failwith "Cannot specify --unix and --xen together."
    | true , false -> `Xen
    | false, _ -> default_unix
  end

let file =
  let doc = Arg.info ~docv:"FILE"
    ~doc:"Configuration file for Mirage. If not specified, the current directory will be scanned. \
          If one file named $(b,config.ml) is found, that file will be used. If no files \
          or multiple configuration files are found, this will result in an error unless one \
          is explicitly specified on the command line." [] in
  Arg.(value & pos 0 (some string) None & doc)

(* CONFIGURE *)
let configure_doc = "Configure a Mirage application."
let configure =
  let doc = configure_doc in
  let man = [
    `S "DESCRIPTION";
    `P "The $(b,configure) command initializes a fresh Mirage application."
  ] in
  let configure unix xen no_macosx no_opam no_opam_version_check file =
    if unix && xen then `Help (`Pager, Some "configure")
    else (
      Mirage.manage_opam_packages (not no_opam);
      Mirage.no_opam_version_check no_opam_version_check;
      Mirage.set_mode (mode unix xen no_macosx);
      let t = Mirage.load file in
      `Ok (Mirage.configure t)) in
  Term.(ret (pure configure $ unix $ xen $ target $ no_opam $
             no_opam_version_check $ file)),
  term_info "configure" ~doc ~man

(* BUILD *)
let build_doc = "Build a Mirage application."
let build =
  let doc = build_doc in
  let man = [
    `S "DESCRIPTION";
    `P build_doc
  ] in
  let build file =
    let t = Mirage.load file in
    `Ok (Mirage.build t) in
  Term.(ret (pure build $ file)), term_info "build" ~doc ~man

(* RUN *)
let run_doc = "Run a Mirage application."
let run =
  let doc = run_doc in
  let man = [
    `S "DESCRIPTION";
    `P "Run a Mirage application on the selected backend."] in
  let run file =
    let t = Mirage.load file in
    `Ok (Mirage.run t) in
  Term.(ret (pure run $ file)), term_info "run" ~doc ~man

(* CLEAN *)
let clean_doc = "Clean the files produced by Mirage for a given application."
let clean =
  let doc = clean_doc in
  let man = [
    `S "DESCRIPTION";
    `P clean_doc;
  ] in
  let clean file no_opam =
    let t = Mirage.load file in
    Mirage.manage_opam_packages (not no_opam);
    `Ok (Mirage.clean t) in
  Term.(ret (pure clean $ file $ no_opam)), term_info "clean" ~doc ~man

(* HELP *)
let help =
  let doc = "Display help about Mirage and Mirage commands." in
  let man = [
    `S "DESCRIPTION";
    `P "Prints help about Mirage commands.";
    `P "Use `$(mname) help topics' to get the full list of help topics.";
  ] in
  let topic =
    let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
    Arg.(value & pos 0 (some string) None & doc )
  in
  let help man_format cmds topic = match topic with
    | None       -> `Help (`Pager, None)
    | Some topic ->
      let topics = "topics" :: cmds in
      let conv, _ = Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
      match conv topic with
      | `Error e -> `Error (false, e)
      | `Ok t when t = "topics" -> List.iter print_endline cmds; `Ok ()
      | `Ok t -> `Help (man_format, Some t) in

  Term.(ret (pure help $Term.man_format $Term.choice_names $topic)),
  Term.info "help" ~doc ~man

let default =
  let doc = "Mirage application builder" in
  let man = [
    `S "DESCRIPTION";
    `P "Mirage is a Mirage application builder. It glues together a set of libaries and configuration (e.g. network and storage) into a standalone unikernel or UNIX binary.";
    `P "Use either $(b,mirage <command> --help) or $(b,mirage help <command>) \
        for more information on a specific command.";
  ] @  help_sections
  in
  let usage () =
    Printf.printf
      "usage: mirage [--version]\n\
      \              [--help]\n\
      \              <command> [<args>]\n\
      \n\
      The most commonly used mirage commands are:\n\
      \    configure   %s\n\
      \    build       %s\n\
      \    run         %s\n\
      \    clean       %s\n\
      \n\
      See 'mirage help <command>' for more information on a specific command.\n%!"
      configure_doc build_doc run_doc clean_doc in
  Term.(pure usage $ pure ()),
  Term.info "mirage"
    ~version:"2.0.0"
    ~sdocs:global_option_section
    ~doc
    ~man

let commands = [
  configure;
  build;
  run;
  clean;
]

let () =
  (* Do not die on Ctrl+C: necessary when mirage has to cleanup things
     (like killing running kernels) before terminating. *)
  Sys.catch_break true;
  match Term.eval_choice default commands with
  | `Error _ -> exit 1
  | _ -> ()
