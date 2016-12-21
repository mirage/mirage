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

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ())

open Cmdliner

let global_option_section = "COMMON OPTIONS"

let setup_log =
  Term.(const setup_log
        $ Fmt_cli.style_renderer ~docs:global_option_section ()
        $ Logs_cli.level ~docs:global_option_section ())

let help_sections = [
  `S global_option_section;
  `P "These options are common to all commands.";
]

(** Helpers *)
let mk_flag ?(section=global_option_section) flags doc =
  let doc = Arg.info ~docs:section ~doc flags in
  Arg.(value & flag & doc)

let term_info title ~doc ~man ~arg =
  let man = man @ help_sections in
  (arg, Term.info ~sdocs:global_option_section ~doc ~man title)

(**
 * Argument specifications
 *)

(** Argument specification for --eval *)
let full_eval =
  let eval_doc =
    Arg.info ~docs:global_option_section ["eval"]
    ~doc:"Fully evaluate the graph before showing it. \
          The default when the unikernel has already been configured."
  in
  let no_eval_doc =
    Arg.info ~docs:global_option_section ["no-eval"]
    ~doc:"Do not evaluate the graph before showing it. See ${b,--eval}. \
          The default when the unikernel has not been configured."
  in
  let eval_opts = [ (Some true, eval_doc) ; (Some false, no_eval_doc) ] in
  Arg.(value & vflag None eval_opts)

(** Argument specification for --dot *)
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
  Arg.(value & opt file "config.ml" & doc)

(** Argument specification for -o FILE or --output=FILE *)
let output =
  let doc =
    Arg.info ~docs:global_option_section ~docv:"FILE" ["o"; "output"]
      ~doc:"File where to output description or dot representation."
  in
  Arg.(value & opt (some string) None & doc)

type 'a describe_args = {
  result: 'a;
  dotcmd: string;
  dot: bool;
  output: string option;
}

type 'a action =
    Configure of 'a
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Help

(*
 * Subcommand specifications
 *)
module Subcommands =
struct
  (** The 'configure' subcommand *)
  let configure result =
    term_info "configure"
      ~doc:"Configure a $(mname) application."
      ~man:[
        `S "DESCRIPTION";
        `P "The $(b,configure) command initializes a fresh $(mname) application."
      ]
      ~arg:Term.(const (fun _ _ info -> Configure info)
                 $ setup_log
                 $ config_file
                 $ result)

  (** The 'describe' subcommand *)
  let describe result =
    term_info "describe"
      ~doc:"Describe a $(mname) application."
      ~man:[
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
      ]
      ~arg:Term.(const (fun _ _ _ info output dotcmd dot ->
          Describe { result = info; dotcmd; dot; output })
                 $ setup_log
                 $ full_eval
                 $ config_file
                 $ result
                 $ output
                 $ dotcmd
                 $ dot)

  (** The 'build' subcommand *)
  let build result =
    let doc = "Build a $(mname) application." in
    term_info "build" ~doc
      ~man:[
        `S "DESCRIPTION";
        `P doc;
      ]
      ~arg:Term.(const (fun _ _ info -> Build info)
                 $ setup_log
                 $ config_file
                 $ result)

  (** The 'clean' subcommand *)
  let clean info_ =
    let doc = "Clean the files produced by $(mname) for a given application." in
    term_info "clean" ~doc
      ~man:[
        `S "DESCRIPTION";
        `P doc;
      ]
      ~arg:Term.(const (fun _ _ info -> Clean info)
                 $ setup_log
                 $ config_file
                 $ info_)

  (** The 'help' subcommand *)
  let help base_context =
    let topic =
      let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
      Arg.(value & pos 0 (some string) None & doc )
    in
    let help man_format cmds topic _keys =
      match topic with
      | None       -> `Help (`Pager, None)
      | Some topic ->
        let parser, _ = Arg.enum (List.rev_map (fun s -> (s, s)) ("topics" :: cmds)) in
        match parser topic with
        | `Error e -> `Error (false, e)
        | `Ok t when t = "topics" -> List.iter print_endline cmds; `Ok ()
        | `Ok t -> `Help (man_format, Some t) in
    (Term.(const (fun _ _ () -> Help) $ setup_log $ config_file $
           ret (Term.(const help $ Term.man_format $ Term.choice_names
                      $ topic $ base_context))),
     Term.info "help"
       ~doc:"Display help about $(mname) commands."
       ~man:[
         `S "DESCRIPTION";
         `P "Prints help.";
         `P "Use `$(mname) help topics' to get the full list of help topics.";
       ])

  let default ~name ~version =
    let usage = `Help (`Plain, None)
    in
    (Term.(ret (pure usage) $ setup_log),
     Term.info name
       ~version
       ~sdocs:global_option_section
       ~doc:"The $(mname) application builder"
       ~man:([
           `S "DESCRIPTION";
           `P "The $(mname) application builder. It glues together a set of \
               libraries and configuration (e.g. network and storage) into a \
               standalone unikernel or UNIX binary.";
           `P "Use either $(b,$(mname) <command> --help) or \
               $(b,($mname) help <command>) for more information on a specific \
               command.";
         ] @  help_sections))
end

(*
 * Functions for extracting particular flags from the command line.
 *)
let read_config_file : string array -> Fpath.t option =
  fun argv -> match Term.eval_peek_opts ~argv config_file with
    | _, `Ok config when Fpath.is_seg config ->
      if Sys.file_exists config && not (Sys.is_directory config) then
        Some (Fpath.v config)
      else
        None
    | _ -> invalid_arg "config must be an existing file (single segment)"

let read_full_eval : string array -> bool option =
  fun argv -> match Term.eval_peek_opts ~argv full_eval with
    | _, `Ok b -> b
    | _ -> None

let parse_args ~name ~version ~configure ~describe ~build ~clean ~help argv =
  Cmdliner.Term.eval_choice ~argv ~catch:false (Subcommands.default ~name ~version) [
    Subcommands.configure configure;
    Subcommands.describe describe;
    Subcommands.build build;
    Subcommands.clean clean;
    Subcommands.help help;
  ]
