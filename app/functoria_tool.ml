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

let fatalize_error = function
  | Ok x    -> x
  | Error s -> Functoria_misc.Log.fatal "%s" s

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
  mk_flag ["no-opam-version-check"] "Bypass the OPAM version check."

let no_depext =
  mk_flag ["no-depext"] "Skip installation of external dependencies."

let full_eval =
  mk_flag ["eval"]
    "Fully evaluate the graph before showing it. \
     By default, only the keys that are given on the command line are \
     evaluated."

let dot =
  mk_flag ["dot"]
    "Output a dot description. \
     If no output file is given,  it will display the dot file using the command \
     given to $(b,--dot-command)."

(** Argument specification for --dot-command=COMMAND *)
let dotcmd =
  let doc =
    Arg.info ~docs:global_option_section ~docv:"COMMAND" [ "dot-command" ]
      ~doc:"Command used to show a dot file. This command should accept a \
            dot file on its standard input."
  in
  Arg.(value & opt string "xdot" & doc)

(** Argument specification for -f CONFIG_FILE or --file=CONFIG_FILE *)
let config_file =
  let doc =
    Arg.info ~docs:global_option_section ~docv:"CONFIG_FILE" ["f"; "file"]
      ~doc:"Configuration file. If not specified, the current directory will \
            be scanned. If one file named $(b,config.ml) is found, that file \
            will be used. If no files or multiple configuration files are \
            found, this will result in an error unless one is explicitly \
            specified on the command line."
  in
  Arg.(value & opt (some file) None & doc)

(** Argument specification for -o FILE or --output=FILE *)
let output =
  let doc =
    Arg.info ~docs:global_option_section ~docv:"FILE" ["o"; "output"]
      ~doc:"File where to output description or dot representation."
  in
  Arg.(value & opt (some string) None & doc)

(** Argument specification for --color=(auto|always|never) *)
let color =
  let enum = [
    "auto"  , None;
    "always", Some `Ansi_tty;
    "never" , Some `None
  ] in
  let color = Arg.enum enum in
  let alts = Arg.doc_alts_enum enum in
  let doc = Arg.info ["color"] ~docs:global_option_section ~docv:"COLOR"
      ~doc:(Fmt.strf "Colorize the output. $(docv) must be %s." alts)
  in
  Arg.(value & opt color None & doc)

let colour_option : string array -> Fmt.style_renderer option =
  fun argv -> match Term.eval_peek_opts ~argv color with
    | _, `Ok color -> color
    | _ -> None

let read_config_file : string array -> string option =
  fun argv -> match Term.eval_peek_opts ~argv config_file with
  | _, `Ok config -> config
  | _ -> None

(** Argument specification for -v or --verbose *)
let verbose : Functoria_misc.Log.level Term.t =
  let log_level_of_verbosity = function
    | []  -> Functoria_misc.Log.WARN
    | [_] -> Functoria_misc.Log.INFO
    | _   -> Functoria_misc.Log.DEBUG
  in
  let doc =
    Arg.info ~docs:global_option_section ~doc:"Be verbose" ["verbose";"v"]
  in
  Term.(pure log_level_of_verbosity $ Arg.(value & flag_all doc))

let init_format color =
  let i = Functoria_misc.Terminfo.columns () in
  Functoria_misc.Log.set_color color;
  Format.pp_set_margin Format.std_formatter i;
  Format.pp_set_margin Format.err_formatter i;
  Fmt_tty.setup_std_outputs ?style_renderer:color ()

let read_log_level argv =
  match Term.eval_peek_opts ~argv verbose with
  | _, `Ok v -> v
  | _, (`Help | `Version | `Error _) -> Functoria_misc.Log.WARN

let load_fully_eval argv =
  match snd @@ Term.eval_peek_opts ~argv full_eval with
  | `Ok b -> b
  | _ -> false

type 'a subcommand_info = {
  doc: string;
  man: Manpage.block list;
  opts: 'a Term.t;
}

(** Subcommand information *)
let configure_info = {
  doc = "Configure a $(mname) application.";
  man = [
    `S "DESCRIPTION";
    `P "The $(b,configure) command initializes a fresh $(mname) application."
    ];
  opts = Term.(pure (fun a b c -> (a, b, c))
               $ no_opam
               $ no_opam_version_check
               $ no_depext)
}

let describe_info = {
  doc = "Describe a $(mname) application.";
  man = [
    `S "DESCRIPTION";
    `P "The $(b,describe) command describes the configuration of a \
        $(mname) application.";
    `P "The dot output contains the following elements:";
    `Noblank;
    `I ("If vertices",
        "Represented as circles. Branches are dotted, and the default branch \
         is in bold.");
    `Noblank;
    `I ("Configurables",
        "Represented as rectangles. The order of the output arrows is \
         the order of the functor arguments.");
    `Noblank;
    `I ("Data dependencies",
        "Represented as dashed arrows.");
    `Noblank;
    `I ("App vertices",
        "Represented as diamonds. The bold arrow is the functor part.");
  ];
  opts = Term.(pure (fun a b c -> (a, b, c))
              $ output
              $ dotcmd
              $ dot);
}

let build_info =
  let doc = "Build a $(mname) application." in
  { doc;
    man = [
      `S "DESCRIPTION";
      `P doc;
    ];
    opts = Term.pure () }

let clean_info =
  let doc = "Clean the files produced by $(mname) for a given application." in
  { doc;
    man = [
      `S "DESCRIPTION";
      `P doc;
    ];
    opts = Term.pure (); }

module Make (Config: Functoria_sigs.CONFIG) = struct

  (* CONFIGURE *)
  let configure config argv =
    let configure info (no_opam, no_opam_version, no_depext) =
      Config.configure info ~no_opam ~no_depext ~no_opam_version
    in
    let if_context = Config.if_context config in
    let context = match Term.eval_peek_opts ~argv if_context with
      | Some context, _ -> context
      | _ ->
        (* If peeking has failed, this should always fail too, but with
           a good error message. *)
        Functoria_key.empty_context
    in
    let term = Term.app (Term.pure configure)
        (Config.eval ~with_required:true ~partial:false context config) in
    (Term.(pure (fun _ _ _ -> fatalize_error) $ verbose $ color $ config_file
           $ (term $ configure_info.opts)),
     term_info "configure" ~doc:configure_info.doc ~man:configure_info.man)

  (* DESCRIBE *)
  let describe config argv =
    let describe info (output, dotcmd, dot) =
      Config.describe ~dotcmd ~dot ~output info in
    let if_context = Config.if_context config in
    let partial = not (load_fully_eval argv) in
    let context = match Term.eval_peek_opts ~argv if_context with
      | Some context, _ -> context
      | _ ->
        (* If peeking has failed, this should always fail too, but with
           a good error message. *)
        Functoria_key.empty_context
    in
    let term = Term.app (Term.pure describe)
        (Config.eval ~with_required:false ~partial context config) in
    (Term.(pure (fun _ t -> t)
           $ full_eval
           $ (Term.(pure (fun _ _ _ -> fatalize_error)
                    $ verbose
                    $ color
                    $ config_file
                    $ (term $ describe_info.opts)))),
     term_info "describe" ~doc:describe_info.doc ~man:describe_info.man)

  (* BUILD *)
  let build config argv =
    let build info () = Config.build info in
    let if_context = Config.if_context config in
    let context = match Term.eval_peek_opts ~argv if_context with
      | Some context, _ -> context
      | _ ->
        (* If peeking has failed, this should always fail too, but with
           a good error message. *)
        Functoria_key.empty_context
    in
    let term = Term.app (Term.pure build)
        (Config.eval ~with_required:false ~partial:false context config) in
    (Term.(pure (fun _ _ _ -> fatalize_error)
            $ verbose
            $ color
            $ config_file
            $ (term $ build_info.opts)),
     term_info "build" ~doc:build_info.doc ~man:build_info.man)

  (* CLEAN *)
  let clean config argv =
    let clean info () = Config.clean info in
    let if_context = Config.if_context config in
    let context = match Term.eval_peek_opts ~argv if_context with
      | Some context, _ -> context
      | _ ->
        (* If peeking has failed, this should always fail too, but with
           a good error message. *)
        Functoria_key.empty_context
    in
    let term = Term.app (Term.pure clean)
        (Config.eval ~with_required:false ~partial:false context config) in
    ((Term.(pure (fun _ _ _ -> fatalize_error) $ verbose $ color $ config_file
             $ (term $ clean_info.opts))),
     term_info "clean" ~doc:clean_info.doc ~man:clean_info.man)

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
    let help (verbose : Functoria_misc.Log.level) color man_format cmds topic _keys =
      Functoria_misc.Log.set_level verbose;
      init_format color;
      match topic with
      | None       -> `Help (`Pager, None)
      | Some topic ->
        let parser, _ = Arg.enum (List.rev_map (fun s -> (s, s)) ("topics" :: cmds)) in
        match parser topic with
        | `Error e -> `Error (false, e)
        | `Ok t when t = "topics" -> List.iter print_endline cmds; `Ok ()
        | `Ok t -> `Help (man_format, Some t) in
    let term =
      Term.(pure help $ verbose $ color $ Term.man_format $ Term.choice_names
            $ topic $ Config.base_context)
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
    let usage verbose color =
      Functoria_misc.Log.set_level verbose;
      init_format color;
      `Help (`Plain, None)
    in
    let term = Term.(ret (pure usage $ verbose $ color)) in
    term,
    Term.info Config.name
      ~version:Config.version
      ~sdocs:global_option_section
      ~doc
      ~man
end

let initialize (module Config:Functoria_sigs.CONFIG) ~argv =
  let module M = Make(Config) in
  let open M in 
  try
    let () = Functoria_misc.Log.set_level (read_log_level argv) in
    (* We really want the color options to be set before loading the config. *)
    let () = init_format (colour_option argv) in
    let config = 
      let c = read_config_file argv in
      let _ = Term.eval_peek_opts ~argv Config.base_context in
      fatalize_error (Config.load c)
    in
    let commands = [
      configure config argv;
      describe config argv;
      build config argv;
      clean config argv;
      help;
    ] in
    match Term.eval_choice ~argv ~catch:false default commands with
      | `Error _ -> exit 1
      | `Ok ()
      | `Version
      | `Help -> ()
  with
  | Functoria_misc.Log.Fatal s ->
    Functoria_misc.Log.show_error "%s" s ;
    exit 1
