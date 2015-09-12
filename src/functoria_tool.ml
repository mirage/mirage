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
open Functoria_misc

module Make (Config : Functoria_sigs.CONFIG) = struct

  let cmdname = Config.name

  let global_option_section = "COMMON OPTIONS"
  let help_sections = [
    `S global_option_section;
    `P "These options are common to all commands.";
  ]

  (* Helpers *)
  let mk_flag ?(section=global_option_section) flags doc =
    let doc = Arg.info ~docs:section ~doc flags in
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

  let full_eval =
    mk_flag ["eval"]
      "Fully evaluate the graph before showing it. By default, only the key \
       that are given on the command line are evaluated."

  let dot =
    mk_flag ["dot"]
      "Output a dot description. If no output file is given, \
       it will show the dot file using command given to $(b,--dot-command)."

  let dotcmd =
    let doc = Arg.info ~docs:global_option_section ~docv:"COMMAND"
        ~doc:"Command used to show a dot file. \
              This command should accept a dot file on its standard input."
        [ "dot-command" ] in
    Arg.(value & opt string "xdot" & doc)

  let file =
    let doc = Arg.info ~docs:global_option_section ~docv:"CONFIG_FILE"
        ~doc:"Configuration file. If not specified, the current directory will be scanned. \
              If one file named $(b,config.ml) is found, that file will be used. If no files \
              or multiple configuration files are found, this will result in an error unless one \
              is explicitly specified on the command line." ["f"; "file"] in
    Arg.(value & opt (some file) None & doc)

  let output =
    let doc = Arg.info ~docs:global_option_section ~docv:"FILE"
        ~doc:"File where to output description or dot representation."
        ["o"; "output"]
    in
    Arg.(value & opt (some file) None & doc)

  let () =
    let i = Terminfo.columns () in
    Format.pp_set_margin Format.std_formatter i ;
    Format.pp_set_margin Format.err_formatter i ;
    Fmt_tty.setup_std_outputs ()


  let global_keys = Config.(switching_keys dummy_conf)

  let with_config =
    let config =
      match Term.eval_peek_opts file with
      | _, `Ok config -> config
      | _ -> None
    in
    let _  = Term.eval_peek_opts global_keys in
    let t = lazy (Config.load config) in
    fun f f_no ->
      let term = match Lazy.force t with
        | Ok t ->
          let pkeys = Config.switching_keys t in
          let _ = Term.eval_peek_opts pkeys in
          f @@ Config.eval t
        | Error err -> f_no err
      in
      Term.(ret (pure (fun f _ -> f) $ term $ file))


  (* CONFIGURE *)
  let configure_doc =  "Configure a $(mname) application."
  let configure =
    let doc = configure_doc in
    let man = [
      `S "DESCRIPTION";
      `P "The $(b,configure) command initializes a fresh $(mname) application."
    ] in
    let f t =
      let configure no_opam no_opam_version no_depext info =
        err_cmdliner @@ t#configure info ~no_opam ~no_depext ~no_opam_version in
      Term.(pure configure $ no_opam $ no_opam_version_check $ no_depext $ t#info)
    in
    let f_no err =
      let f _ _ _ () = `Error (false, err) in
      Term.(pure f $ no_opam $ no_opam_version_check $ no_depext $ global_keys)
    in
    with_config f f_no, term_info "configure" ~doc ~man

  (* DESCRIBE *)
  let describe_doc =  "Describe a $(mname) application."
  let describe =
    let doc = describe_doc in
    let man = [
      `S "DESCRIPTION";
      `P "The $(b,describe) command describes the configuration of a \
          $(mname) application.";
      `P "The dot output contains the following elements:";
      `Noblank ;
      `I ("If vertices",
        "Represented as circles. Green/red arrows are the then/else branches. \
         Bold is the default branch.");
      `Noblank ;
      `I ("Configurables",
        "Represented as rectangles. The order of the output arrows is \
         the order of the functor arguments.");
      `Noblank ;
      `I ("Data dependencies",
        "Represented as dashed arrows");
      `Noblank ;
      `I ("App vertices",
        "Represented as diamonds. The bold arrow is the functor part.");
    ] in
    let f t =
      let describe _ filename dotcmd dot eval =
        `Ok (t#describe ~dotcmd ~dot ~eval filename)
      in
      Term.(pure describe $ t#info $ output $ dotcmd $ dot $ full_eval)
    in
    let f_no err =
      let f () = `Error (false, err) in
      Term.(pure f $ global_keys)
    in
    with_config f f_no, term_info "describe" ~doc ~man

  (* BUILD *)
  let build_doc = "Build a $(mname) application."
  let build =
    let doc = build_doc in
    let man = [
      `S "DESCRIPTION";
      `P build_doc
    ] in
    let f t =
      let build info = err_cmdliner (t#build info) in
      Term.(pure build $ t#info)
    in
    let f_no err =
      let f = `Error (false, err) in
      Term.(pure f)
    in
    with_config f f_no, term_info "build" ~doc ~man

  (* CLEAN *)
  let clean_doc =
    "Clean the files produced by $(mname) for a given application."
  let clean =
    let doc = clean_doc in
    let man = [
      `S "DESCRIPTION";
      `P clean_doc;
    ] in
    let f t =
      let clean info =
        err_cmdliner @@ t#clean info in
      Term.(pure clean $ t#info)
    in
    let f_no err =
      let f _ = `Error (false, err) in
      Term.(pure f $ no_opam)
    in
    with_config f f_no, term_info "clean" ~doc ~man

  (* HELP *)
  let help =
    let doc = "Display help about $(mname) commands." in
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
    let term =
      Term.(pure help $ Term.man_format $ Term.choice_names $ topic $ global_keys)
    in
    Term.ret term, Term.info "help" ~doc ~man

  let default =
    let doc = "The $(mname) application builder" in
    let man = [
      `S "DESCRIPTION";
      `P "The $(mname) application builder. It glues together a set of libraries and configuration (e.g. network and storage) into a standalone unikernel or UNIX binary." ;
      `P "Use either $(b,$(mname) <command> --help) or \
          $(b,($mname) help <command>) for more information on a specific command."
      ;
    ] @  help_sections
    in
    let usage = `Help (`Plain, None) in
    let term = Term.(ret @@ pure usage) in
    term,
    Term.info cmdname
      ~version:Config.version
      ~sdocs:global_option_section
      ~doc
      ~man

  let commands = [
    configure;
    describe;
    build;
    clean;
    help;
  ]

  let () =
    match Term.eval_choice default commands with
    | `Error _ -> exit 1
    | _ -> ()

end
