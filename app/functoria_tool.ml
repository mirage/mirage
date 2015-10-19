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
open Rresult
open Functoria_misc

module Make (Config: Functoria_sigs.CONFIG) = struct

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
    mk_flag ["no-opam"]
      "Do not manage the OPAM configuration. \
       This will result in dependent libraries not being automatically \
       installed during the configuration phase."

  let no_opam_version_check =
    mk_flag ["no-opam-version-check"] "Bypass the check of opam's version."

  let no_depext =
    mk_flag ["no-depext"] "Skip installation of external dependencies."

  let full_eval =
    mk_flag ["eval"]
      "Fully evaluate the graph before showing it. \
       By default, only the key that are given on the command line are \
       evaluated."

  let dot =
    mk_flag ["dot"]
      "Output a dot description. \
       If no output file is given,  it will show the dot file using command \
       given to $(b,--dot-command)."

  let dotcmd =
    let doc =
      Arg.info ~docs:global_option_section ~docv:"COMMAND" [ "dot-command" ]
        ~doc:"Command used to show a dot file. This command should accept a \
              dot file on its standard input."
    in
    Arg.(value & opt string "xdot" & doc)

  let file =
    let doc =
      Arg.info ~docs:global_option_section ~docv:"CONFIG_FILE" ["f"; "file"]
        ~doc:"Configuration file. If not specified, the current directory will \
              be scanned. If one file named $(b,config.ml) is found, that file \
              will be used. If no files or multiple configuration files are \
              found, this will result in an error unless one is explicitly \
              specified on the command line."
    in
    Arg.(value & opt (some file) None & doc)

  let output =
    let doc =
      Arg.info ~docs:global_option_section ~docv:"FILE" ["o"; "output"]
        ~doc:"File where to output description or dot representation."
    in
    Arg.(value & opt (some string) None & doc)

  let color =
    let enum = ["auto", None; "always", Some `Ansi_tty; "never", Some `None] in
    let color = Arg.enum enum in
    let alts = Arg.doc_alts_enum enum in
    let doc = Arg.info ["color"] ~docs:global_option_section ~docv:"WHEN"
        ~doc:(Fmt.strf "Colorize the output. $(docv) must be %s." alts)
    in
    Arg.(value & opt color None & doc)

  let init_format color =
    let i = Terminfo.columns () in
    Format.pp_set_margin Format.std_formatter i;
    Format.pp_set_margin Format.err_formatter i;
    Fmt_tty.setup_std_outputs ?style_renderer:color ()

  let load_config () =
    let c = match Term.eval_peek_opts file with
      | _, `Ok config -> config
      | _ -> None
    in
    let _ = Term.eval_peek_opts Config.base_context in
    Config.load c

  let load_color () =
    (* This is ugly but we really want the color options to be set
       before calling [load_config]. *)
    let c = match Term.eval_peek_opts color with
      | _, `Ok color -> color
      | _ -> None
    in
    init_format c

  let config = Lazy.from_fun load_config
  let set_color  = Lazy.from_fun load_color

  let with_config f options =
    Lazy.force set_color;
    let show_error = function
      | Ok r    -> r
      | Error s -> Log.show_error "%s" s
    in
    let term = match Lazy.force config with
      | Ok t ->
        let if_context = Config.if_context t in
        let term = match Term.eval_peek_opts if_context with
          | Some context, _ -> f if_context context t
          | _, _ -> Term.pure (fun _ -> Error "Error during peeking.")
        in term
      | Error err -> Term.pure (fun _ -> Error err)
    in
    Term.(pure (fun _ _ -> show_error) $ color $ file $ (term $ options))

  (* CONFIGURE *)
  let configure_doc =  "Configure a $(mname) application."
  let configure =
    let doc = configure_doc in
    let man = [
      `S "DESCRIPTION";
      `P "The $(b,configure) command initializes a fresh $(mname) application."
    ] in
    let options =
      Term.(pure (fun a b c -> a, b, c) $ no_opam $ no_opam_version_check $ no_depext)
    in
    let configure info (no_opam, no_opam_version, no_depext) =
      Config.configure info ~no_opam ~no_depext ~no_opam_version
    in
    let f _ map conf = Term.(pure configure $ Config.eval map conf) in
    with_config f options, term_info "configure" ~doc ~man

  (* DESCRIBE *)
  let describe_doc =  "Describe a $(mname) application."
  let describe =
    let doc = describe_doc in
    let man = [
      `S "DESCRIPTION";
      `P "The $(b,describe) command describes the configuration of a \
          $(mname) application.";
      `P "The dot output contains the following elements:";
      `Noblank;
      `I ("If vertices",
          "Represented as circles. Branches are doted, the default branch \
           is in bold.");
      `Noblank;
      `I ("Configurables",
          "Represented as rectangles. The order of the output arrows is \
           the order of the functor arguments.");
      `Noblank;
      `I ("Data dependencies",
          "Represented as dashed arrows");
      `Noblank;
      `I ("App vertices",
          "Represented as diamonds. The bold arrow is the functor part.");
    ] in
    let options =
      Term.(pure (fun a b c d -> a, b, c, d)
            $ output $ dotcmd $ dot $ full_eval)
    in
    let f if_keys map t =
      let describe _ (output, dotcmd, dot, eval) =
        Config.describe ~dotcmd ~dot ~eval ~output map t
      in
      Term.(pure describe $ if_keys)
    in
    with_config f options, term_info "describe" ~doc ~man

  (* BUILD *)
  let build_doc = "Build a $(mname) application."
  let build =
    let doc = build_doc in
    let man = [
      `S "DESCRIPTION";
      `P build_doc
    ] in
    let options = Term.pure () in
    let build info () = Config.build info in
    let f _ map conf = Term.(pure build $ Config.eval map conf) in
    with_config f options, term_info "build" ~doc ~man

  (* CLEAN *)
  let clean_doc =
    "Clean the files produced by $(mname) for a given application."
  let clean =
    let doc = clean_doc in
    let man = [
      `S "DESCRIPTION";
      `P clean_doc;
    ] in
    let options = Term.pure () in
    let clean info () = Config.clean info in
    let f _ map conf = Term.(pure clean $ Config.eval map conf) in
    with_config f options, term_info "clean" ~doc ~man

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
    let help color man_format cmds topic _keys =
      init_format color;
      match topic with
      | None       -> `Help (`Pager, None)
      | Some topic ->
        let topics = "topics" :: cmds in
        let conv, _ = Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
        match conv topic with
        | `Error e -> `Error (false, e)
        | `Ok t when t = "topics" -> List.iter print_endline cmds; `Ok ()
        | `Ok t -> `Help (man_format, Some t) in
    let term =
      Term.(pure help $ color $ Term.man_format $ Term.choice_names $ topic
            $ Config.base_context)
    in
    Term.ret term, Term.info "help" ~doc ~man

  let default =
    let doc = "The $(mname) application builder" in
    let man = [
      `S "DESCRIPTION";
      `P "The $(mname) application builder. It glues together a set of \
          libraries and configuration (e.g. network and storage) into a \
          standalone unikernel or UNIX binary.";
      `P "Use either $(b,$(mname) <command> --help) or \
          $(b,($mname) help <command>) for more information on a specific \
          command.";
    ] @  help_sections
    in
    let usage color = init_format color; `Help (`Plain, None) in
    let term = Term.(ret (pure usage $ color)) in
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
