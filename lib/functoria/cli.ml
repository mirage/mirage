(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

type query_kind =
  [ `Packages | `Opam | `Install | `Files of [ `Configure | `Build ] ]

let query_kinds : (string * query_kind) list =
  [
    ("packages", `Packages);
    ("opam", `Opam);
    ("install", `Install);
    ("files-configure", `Files `Configure);
    ("files-build", `Files `Build);
  ]

let setup ~with_setup =
  Term.(
    const (if with_setup then setup_log else fun _ _ -> ())
    $ Fmt_cli.style_renderer ~docs:common_section ()
    $ Logs_cli.level ~docs:common_section ())

let config_file =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The configuration file to use." [ "f"; "file" ]
  in
  Term.(const Fpath.v $ Arg.(value & opt string "config.ml" & doc))

let dry_run =
  let doc =
    Arg.info ~docs:configuration_section
      ~doc:"Display I/O actions instead of executing them." [ "dry-run" ]
  in
  Arg.(value & flag doc)

(** * Argument specifications *)

(** Argument specification for --eval *)
let full_eval =
  let eval_doc =
    Arg.info ~docs:description_section [ "eval" ]
      ~doc:
        "Fully evaluate the graph before showing it. The default when the \
         unikernel has already been configured."
  in
  let no_eval_doc =
    Arg.info ~docs:description_section [ "no-eval" ]
      ~doc:
        "Do not evaluate the graph before showing it. See $(b,--eval). The \
         default when the unikernel has not been configured."
  in
  let eval_opts = [ (Some true, eval_doc); (Some false, no_eval_doc) ] in
  Arg.(value & vflag None eval_opts)

(** Argument specification for --dot *)
let dot =
  let doc =
    Arg.info ~docs:description_section [ "dot" ]
      ~doc:
        "Output a dot description. If no output file is given, it will display \
         the dot file using the  command  given to $(b,--dot-command)."
  in
  Arg.(value & flag doc)

(** Argument specification for --dot-command=COMMAND *)
let dotcmd =
  let doc =
    Arg.info ~docs:description_section ~docv:"COMMAND" [ "dot-command" ]
      ~doc:
        "Command used to show a dot file. This command should accept a dot \
         file on its standard input."
  in
  Arg.(value & opt string "xdot" & doc)

(** Argument specification for -o FILE or --output=FILE *)
let output =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE" [ "o"; "output" ]
      ~doc:"Name of the output file."
  in
  Arg.(value & opt (some string) None & doc)

let kind =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"INFO" []
      ~doc:"The information to query."
  in
  Arg.(value & pos 0 (enum query_kinds) `Packages & doc)

type 'a args = {
  context : 'a;
  config_file : Fpath.t;
  output : string option;
  dry_run : bool;
}

type 'a configure_args = 'a args

type 'a build_args = 'a args

type 'a clean_args = 'a args

type 'a help_args = 'a args

type 'a describe_args = {
  args : 'a args;
  dotcmd : string;
  dot : bool;
  eval : bool option;
}

type 'a query_args = { args : 'a args; kind : query_kind }

type 'a action =
  | Configure of 'a configure_args
  | Query of 'a query_args
  | Describe of 'a describe_args
  | Build of 'a build_args
  | Clean of 'a clean_args
  | Help of 'a help_args

(*
 * Pretty-printing
 *)

let pp_args pp_a =
  let open Fmt.Dump in
  record
    [
      field "context" (fun (t : 'a configure_args) -> t.context) pp_a;
      field "config_file" (fun t -> t.config_file) Fpath.pp;
      field "output" (fun t -> t.output) (option string);
      field "dry_run" (fun t -> t.dry_run) Fmt.bool;
    ]

let pp_configure = pp_args

let pp_build = pp_args

let pp_clean = pp_args

let pp_help = pp_args

let pp_kind ppf (q : query_kind) =
  let rec aux = function
    | [] -> invalid_arg "missing query kind!"
    | (a, b) :: t -> if b = q then Fmt.Dump.string ppf a else aux t
  in
  aux query_kinds

let pp_query pp_a =
  let open Fmt.Dump in
  record
    [
      field "args" (fun (t : 'a query_args) -> t.args) (pp_args pp_a);
      field "kind" (fun t -> t.kind) pp_kind;
    ]

let pp_describe pp_a =
  let open Fmt.Dump in
  record
    [
      field "args" (fun (t : 'a describe_args) -> t.args) (pp_args pp_a);
      field "dotcmd" (fun t -> t.dotcmd) string;
      field "dot" (fun t -> t.dot) Fmt.bool;
      field "eval" (fun t -> t.eval) (option Fmt.bool);
    ]

let pp_action pp_a ppf = function
  | Configure c -> Fmt.pf ppf "@[configure:@ @[<2>%a@]@]" (pp_configure pp_a) c
  | Query q -> Fmt.pf ppf "@[query:@ @[<2>%a@]@]" (pp_query pp_a) q
  | Describe d -> Fmt.pf ppf "@[describe:@ @[<2>%a@]@]" (pp_describe pp_a) d
  | Build b -> Fmt.pf ppf "@[build:@ @[<2>%a@]@]" (pp_build pp_a) b
  | Clean c -> Fmt.pf ppf "@[clean:@ @[<2>%a@]@]" (pp_clean pp_a) c
  | Help h -> Fmt.pf ppf "@[help:@ @[<2>%a@]@]" (pp_help pp_a) h

let args ~with_setup context =
  Term.(
    const (fun () config_file dry_run output context ->
        { config_file; dry_run; output; context })
    $ setup ~with_setup
    $ config_file
    $ dry_run
    $ output
    $ context)

(*
 * Subcommand specifications
 *)

module Subcommands = struct
  (** The 'configure' subcommand *)
  let configure ~with_setup context =
    ( Term.(const (fun args -> Configure args) $ args ~with_setup context),
      Term.info "configure" ~doc:"Configure a $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,configure) command initializes a fresh $(mname) \
               application.";
          ] )

  let query ~with_setup context =
    ( Term.(
        const (fun kind args -> Query { kind; args })
        $ kind
        $ args ~with_setup context),
      Term.info "query" ~doc:"Query information about the $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,query) command queries information about the $(mname) \
               application.";
          ] )

  (** The 'describe' subcommand *)
  let describe ~with_setup context =
    ( Term.(
        const (fun args eval dotcmd dot -> Describe { args; eval; dotcmd; dot })
        $ args ~with_setup context
        $ full_eval
        $ dotcmd
        $ dot),
      Term.info "describe" ~doc:"Describe a $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,describe) command describes the configuration of a \
               $(mname) application.";
            `P "The dot output contains the following elements:";
            `Noblank;
            `I
              ( "If vertices",
                "Represented as circles. Branches are dotted, and the default \
                 branch is in bold." );
            `Noblank;
            `I
              ( "Configurables",
                "Represented as rectangles. The order of the output arrows is \
                 the order of the functor arguments." );
            `Noblank;
            `I ("Data dependencies", "Represented as dashed arrows.");
            `Noblank;
            `I
              ( "App vertices",
                "Represented as diamonds. The bold arrow is the functor part."
              );
          ] )

  (** The 'build' subcommand *)
  let build ~with_setup context =
    let doc = "Build a $(mname) application." in
    ( Term.(const (fun args -> Build args) $ args ~with_setup context),
      Term.info "build" ~doc ~man:[ `S "DESCRIPTION"; `P doc ] )

  (** The 'clean' subcommand *)
  let clean ~with_setup context =
    let doc = "Clean the files produced by $(mname) for a given application." in
    ( Term.(const (fun args -> Clean args) $ args ~with_setup context),
      Term.info "clean" ~doc ~man:[ `S "DESCRIPTION"; `P doc ] )

  (** The 'help' subcommand *)
  let help ~with_setup context =
    let topic =
      let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
      Arg.(value & pos 0 (some string) None & doc)
    in
    let help man_format cmds topic =
      match topic with
      | None -> `Help (man_format, None)
      | Some topic -> (
          let parser, _ =
            Arg.enum (List.rev_map (fun s -> (s, s)) ("topics" :: cmds))
          in
          match parser topic with
          | `Error e -> `Error (false, e)
          | `Ok t when t = "topics" ->
              List.iter print_endline cmds;
              `Ok ()
          | `Ok t -> `Help (man_format, Some t) )
    in
    ( Term.(
        const (fun args () -> Help args)
        $ args ~with_setup context
        $ ret (const help $ Term.man_format $ Term.choice_names $ topic)),
      Term.info "help" ~doc:"Display help about $(mname) commands."
        ~man:
          [
            `S "DESCRIPTION";
            `P "Prints help.";
            `P "Use `$(mname) help topics' to get the full list of help topics.";
          ] )

  let default ~with_setup ~name ~version =
    let usage = `Help (`Plain, None) in
    ( Term.(ret (pure usage) $ setup ~with_setup),
      Term.info name ~version ~doc:"The $(mname) application builder"
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(mname) application builder. It glues together a set of \
               libraries and configuration (e.g. network and storage) into a \
               standalone unikernel or UNIX binary.";
            `P
              "Use $(mname) $(b,help <command>) for more information on a \
               specific command.";
          ] )
end

(*
 * Functions for extracting particular flags from the command line.
 *)

let peek_full_eval argv =
  match Term.eval_peek_opts ~argv full_eval with _, `Ok b -> b | _ -> None

let peek_output argv =
  match Term.eval_peek_opts ~argv output with _, `Ok b -> b | _ -> None

let peek_args ?(with_setup = false) argv =
  match Term.eval_peek_opts ~argv (args ~with_setup (Term.pure ())) with
  | _, `Ok b | Some b, _ -> b
  | _ -> assert false

let eval ?(with_setup = true) ?help_ppf ?err_ppf ~name ~version ~configure
    ~query ~describe ~build ~clean ~help argv =
  Cmdliner.Term.eval_choice ?help:help_ppf ?err:err_ppf ~argv ~catch:false
    (Subcommands.default ~with_setup ~name ~version)
    [
      Subcommands.configure ~with_setup configure;
      Subcommands.describe ~with_setup describe;
      Subcommands.query ~with_setup query;
      Subcommands.build ~with_setup build;
      Subcommands.clean ~with_setup clean;
      Subcommands.help ~with_setup help;
    ]

let args = function
  | Configure x | Build x | Clean x | Help x -> x
  | Query { args; _ } -> args
  | Describe { args; _ } -> args
