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
open Functoria
open Functoria_misc

module Make (Config : Functoria.CONFIG) = struct

  let cmdname = Config.Project.application_name
  let appname = String.capitalize cmdname

  let key_term keys =
    Key.(term (Set.filter is_configure keys))

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

  let no_opam =
    mk_flag ["no-opam"] "Do not manage the OPAM configuration.  This will result in dependent libraries not being automatically installed during the configuration phase."

  let no_opam_version_check =
    mk_flag ["no-opam-version-check"] "Bypass the check of opam's version."

  let no_depext =
    mk_flag ["no-depext"] "Skip installation of external dependencies."

  let file =
    let doc = Arg.info ~docv:"FILE"
        ~doc:"Configuration file. If not specified, the current directory will be scanned. \
              If one file named $(b,config.ml) is found, that file will be used. If no files \
              or multiple configuration files are found, this will result in an error unless one \
              is explicitly specified on the command line." ["f"; "file"] in
    Arg.(value & opt (some file) None & doc)


  let () =
    let i = Terminfo.columns () in
    Format.pp_set_margin Format.std_formatter i ;
    Format.pp_set_margin Format.err_formatter i ;
    if Terminfo.with_color () then Fmt.set_style_tags `Ansi ;
    if Terminfo.with_utf8 () then Fmt.set_utf_8_enabled true ;
    ()


  let global_keys = key_term @@ Config.(keys dummy_conf)

  let with_config =
    let config =
      match Term.eval_peek_opts file with
      | _, `Ok config -> config
      | _ -> None
    in
    let _  = Term.eval_peek_opts global_keys in
    let t = Config.load config in
    fun f f_no ->
      let term = match t with
        | Ok t ->
          let pkeys = key_term @@ primary_keys t in
          let _ = Term.eval_peek_opts pkeys in
          f t
        | Error err -> f_no err
      in
      Term.(ret (pure (fun x _ -> x) $ term $ file))


  (* CONFIGURE *)
  let configure_doc =
    Printf.sprintf "Configure a %s application." appname
  let configure =
    let doc = configure_doc in
    let man = [
      `S "DESCRIPTION";
      `P (Printf.sprintf "The $(b,configure) command initializes a fresh %s application." appname)
    ] in
    let f t =
      let configure no_opam no_opam_version_check no_depext _keys =
        Config.manage_opam_packages (not no_opam);
        Config.no_opam_version_check no_opam_version_check;
        Config.no_depext no_depext;
        `Ok (Config.configure t) in
      let keys = key_term @@ keys t in
      Term.(pure configure $ no_opam $ no_opam_version_check $ no_depext $ keys)
    in
    let f_no err =
      let f _ _ _ () = `Error (false, err) in
      Term.(pure f $ no_opam $ no_opam_version_check $ no_depext $ global_keys)
    in
    with_config f f_no, term_info "configure" ~doc ~man

  (* BUILD *)
  let build_doc =
    Printf.sprintf "Build a %s application." appname
  let build =
    let doc = build_doc in
    let man = [
      `S "DESCRIPTION";
      `P build_doc
    ] in
    let f t =
      let build () = `Ok (Config.build t) in
      Term.(pure build $ pure ())
    in
    let f_no err =
      let f = `Error (false, err) in
      Term.(pure f)
    in
    with_config f f_no, term_info "build" ~doc ~man

  (* CLEAN *)
  let clean_doc =
    Printf.sprintf "Clean the files produced by %s for a given application." appname
  let clean =
    let doc = clean_doc in
    let man = [
      `S "DESCRIPTION";
      `P clean_doc;
    ] in
    let f t =
      let clean no_opam =
        Config.manage_opam_packages (not no_opam);
        `Ok (Config.clean t) in
      Term.(pure clean $ no_opam)
    in
    let f_no err =
      let f _ = `Error (false, err) in
      Term.(pure f $ no_opam)
    in
    with_config f f_no, term_info "clean" ~doc ~man

  (* HELP *)
  let help =
    let doc =
      Printf.sprintf "Display help about %s and %s commands." appname appname in
    let man = [
      `S "DESCRIPTION";
      `P "Prints help.";
      `P "Use `$(mname) help topics' to get the full list of help topics.";
    ] in
    let topic =
      let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
      Arg.(value & pos 0 (some string) None & doc )
    in
    let help man_format cmds topic _keys = match topic with
      | None       -> `Help (`Pager, None)
      | Some topic ->
        let topics = "topics" :: cmds in
        let conv, _ = Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
        match conv topic with
        | `Error e -> `Error (false, e)
        | `Ok t when t = "topics" -> List.iter print_endline cmds; `Ok ()
        | `Ok t -> `Help (man_format, Some t) in
    let f t =
      let keys = key_term @@ keys t in
      Term.(pure help $ Term.man_format $ Term.choice_names $ topic $ keys)
    in
    let f_no _err =
      Term.(pure help $ Term.man_format $ Term.choice_names $ topic $ global_keys)
    in
    with_config f f_no, Term.info "help" ~doc ~man

  let default =
    let doc = Printf.sprintf "%s application builder" appname in
    let man = [
      `S "DESCRIPTION";
      `P (Printf.sprintf
          "%s is a %s application builder. It glues together a set of libraries and configuration (e.g. network and storage) into a standalone unikernel or UNIX binary."
          cmdname appname
      );
      `P (Printf.sprintf "Use either $(b,%s <command> --help) or $(b,%s help <command>) \
                          for more information on a specific command."
          cmdname cmdname
      ) ;
    ] @  help_sections
    in
    let usage () =
      Printf.printf
        "usage: %s [--version] [--help] <command> [<args>]\n\
         \n\
         The most commonly used %s commands are:\n\
        \    configure   %s\n\
        \    build       %s\n\
        \    clean       %s\n\
         \n\
         See '%s help <command>' for more information on a specific command.\n%!"
        cmdname cmdname configure_doc build_doc clean_doc cmdname ;
      `Ok ()
    in
    let f _ = Term.(pure usage $ global_keys) in
    with_config f f,
    Term.info cmdname
      ~version:Config.Project.version
      ~sdocs:global_option_section
      ~doc
      ~man

  let commands = [
    configure;
    build;
    clean;
    help;
  ]

  let launch () =
    (* Do not die on Ctrl+C: necessary when functoria has to cleanup things
       (like killing running kernels) before terminating. *)
    Sys.catch_break true;
    match Term.eval_choice ~catch:false default commands with
    | `Error _ -> exit 1
    | exception Functoria_misc.Fatal s ->
      Printf.eprintf "%s" s ; exit 1
    | _ -> ()

end
