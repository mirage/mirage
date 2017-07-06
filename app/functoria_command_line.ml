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

let common_section = "COMMON OPTIONS"
let configuration_section = "CONFIGURE OPTIONS"
let description_section = "DESCRIBE OPTIONS"

let setup_log =
  Term.(const setup_log
        $ Fmt_cli.style_renderer ~docs:common_section ()
        $ Logs_cli.level ~docs:common_section ())

let config_file f =
  let doc =
    Arg.info
      ~docs:configuration_section
      ~docv:"FILE"
      ~doc:"The configuration file to use."
      ["f"; "file"]
  in
  Term.(const (fun x ->  f (Fpath.v x))
        $ Arg.(value & opt string "config.ml" & doc))

let build_dir f =
  let doc =
    Arg.info
      ~docs:configuration_section
      ~docv:"DIR"
      ~doc:"The directory where the build is done."
      ["b"; "build-dir"]
  in
  Term.(const (function None -> () | Some x ->  f (Fpath.v x))
        $ Arg.(value & opt (some string) None & doc))

(**
 * Argument specifications
 *)

(** Argument specification for --eval *)
let full_eval =
  let eval_doc =
    Arg.info ~docs:description_section ["eval"]
    ~doc:"Fully evaluate the graph before showing it. \
          The default when the unikernel has already been configured."
  in
  let no_eval_doc =
    Arg.info ~docs:description_section ["no-eval"]
    ~doc:"Do not evaluate the graph before showing it. See ${b,--eval}. \
          The default when the unikernel has not been configured."
  in
  let eval_opts = [ (Some true, eval_doc) ; (Some false, no_eval_doc) ] in
  Arg.(value & vflag None eval_opts)

(** Argument specification for --dot *)
let dot =
  let doc =
    Arg.info ~docs:description_section ["dot"]
      ~doc:"Output a dot description. If no output file is given, it will \
            display the dot file using the  command  given to \
            $(b,--dot-command)."
  in
  Arg.(value & flag doc)

(** Argument specification for --dot-command=COMMAND *)
let dotcmd =
  let doc =
    Arg.info ~docs:description_section ~docv:"COMMAND" [ "dot-command" ]
      ~doc:"Command used to show a dot file. This command should accept a \
            dot file on its standard input."
  in
  Arg.(value & opt string "xdot" & doc)

(** Argument specification for -o FILE or --output=FILE *)
let output =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE" ["o"; "output"]
      ~doc:"Name of the output file."
  in
  Arg.(value & opt (some string) None & doc)

type 'a describe_args = {
  result: 'a;
  dotcmd: string;
  dot: bool;
  output: string option;
}

type 'a configure_args = {
  result: 'a;
  output: string option;
}

type 'a action =
    Configure of 'a configure_args
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Help


(*
 * Pretty-printing
 *)
let pp_configure pp_a ppf (c: 'a configure_args) =
  Fmt.pf ppf "@[result:%a@;output:%a@]"
    pp_a c.result Fmt.(option string) c.output

let pp_describe pp_a ppf (d: 'a describe_args) =
  Fmt.pf ppf "@[result:%a@;dotcmd:%s@;dot:%a@;output:%a@]"
    pp_a d.result d.dotcmd Fmt.bool d.dot Fmt.(option string) d.output

let pp_action pp_a ppf = function
  | Configure c -> Fmt.pf ppf "@[configure:@ @[<2>%a@]@]" (pp_configure pp_a) c
  | Describe d  -> Fmt.pf ppf "@[describe:@ @[<2>%a@]@]" (pp_describe pp_a) d
  | Build b     -> Fmt.pf ppf "@[build:@ @[<2>%a@]@]" pp_a b
  | Clean c     -> Fmt.pf ppf "@[clean:@ @[<2>%a@]@]" pp_a c
  | Help        -> Fmt.string ppf "help"

let setup =
  let noop _ = () in
  Term.(const (fun () () () -> ())
        $ setup_log
        $ config_file noop
        $ build_dir noop)

(*
 * Subcommand specifications
 *)
module Subcommands =
struct
  (** The 'configure' subcommand *)
  let configure result =
    Term.(const (fun _ output result -> Configure { output; result })
          $ setup
          $ output
          $ result),
    Term.info "configure"
      ~doc:"Configure a $(mname) application."
      ~man:[
        `S "DESCRIPTION";
        `P "The $(b,configure) command initializes a fresh $(mname) \
            application."
      ]

  (** The 'describe' subcommand *)
  let describe result =
    Term.(const (fun _ _ info output dotcmd dot ->
        Describe { result = info; dotcmd; dot; output })
          $ setup
          $ full_eval
          $ result
          $ output
          $ dotcmd
          $ dot),
    Term.info "describe"
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

  (** The 'build' subcommand *)
  let build result =
    let doc = "Build a $(mname) application." in
    Term.(const (fun _ info -> Build info)
          $ setup
          $ result),
    Term.info "build" ~doc
      ~man:[
        `S "DESCRIPTION";
        `P doc;
      ]

  (** The 'clean' subcommand *)
  let clean info_ =
    let doc = "Clean the files produced by $(mname) for a given application." in
    Term.(const (fun _ info -> Clean info)
          $ setup
          $ info_),
    Term.info "clean" ~doc
      ~man:[
        `S "DESCRIPTION";
        `P doc;
      ]

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
        | `Ok t -> `Help (man_format, Some t)
    in
    Term.(const (fun _ _ () -> Help)
          $ setup
          $ output
          $ ret (const help
                 $ Term.man_format
                 $ Term.choice_names
                 $ topic
                 $ base_context)),
    Term.info "help"
      ~doc:"Display help about $(mname) commands."
      ~man:[
        `S "DESCRIPTION";
        `P "Prints help.";
        `P "Use `$(mname) help topics' to get the full list of help topics.";
      ]

  let default ~name ~version =
    let usage = `Help (`Plain, None)
    in
    Term.(ret (pure usage) $ setup),
    Term.info name
      ~version
      ~doc:"The $(mname) application builder"
      ~man:[
        `S "DESCRIPTION";
        `P "The $(mname) application builder. It glues together a set of \
            libraries and configuration (e.g. network and storage) into a \
            standalone unikernel or UNIX binary.";
        `P "Use $(mname) $(b,help <command>) for more information on a \
            specific command.";
      ]
end

(*
 * Functions for extracting particular flags from the command line.
 *)
let read_full_eval : string array -> bool option =
  fun argv -> match Term.eval_peek_opts ~argv full_eval with
    | _, `Ok b -> b
    | _ -> None

let parse_args ?help_ppf ?err_ppf
    ~name ~version ~configure ~describe ~build ~clean ~help argv
  =
  Cmdliner.Term.eval_choice ?help:help_ppf ?err:err_ppf ~argv ~catch:false
    (Subcommands.default ~name ~version) [
    Subcommands.configure configure;
    Subcommands.describe describe;
    Subcommands.build build;
    Subcommands.clean clean;
    Subcommands.help help;
  ]
