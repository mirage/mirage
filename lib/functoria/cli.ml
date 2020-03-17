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

let setup_log =
  Term.(
    const setup_log
    $ Fmt_cli.style_renderer ~docs:common_section ()
    $ Logs_cli.level ~docs:common_section ())

let config_file =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The configuration file to use." [ "f"; "file" ]
  in
  Term.(const Fpath.v $ Arg.(value & opt string "config.ml" & doc))

let build_dir =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"DIR"
      ~doc:"The directory where the build is done." [ "b"; "build-dir" ]
  in
  Term.(
    const (function None -> None | Some f -> Some (Fpath.v f))
    $ Arg.(value & opt (some string) None & doc))

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

type 'a describe_args = {
  result : 'a;
  dotcmd : string;
  dot : bool;
  output : string option;
}

type 'a configure_args = { result : 'a; output : string option }

type 'a query_args = { result : 'a; kind : query_kind }

type 'a action =
  | Configure of 'a configure_args
  | Query of 'a query_args
  | Describe of 'a describe_args
  | Build of 'a
  | Clean of 'a
  | Help

(*
 * Pretty-printing
 *)

let pp_configure pp_a =
  let open Fmt.Dump in
  record
    [
      field "result" (fun (t : 'a configure_args) -> t.result) pp_a;
      field "output" (fun t -> t.output) (option string);
    ]

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
      field "result" (fun (t : 'a query_args) -> t.result) pp_a;
      field "kind" (fun t -> t.kind) pp_kind;
    ]

let pp_describe pp_a =
  let open Fmt.Dump in
  record
    [
      field "result" (fun (t : 'a describe_args) -> t.result) pp_a;
      field "dotcmd" (fun t -> t.dotcmd) string;
      field "dot" (fun t -> t.dot) Fmt.bool;
      field "output" (fun (t : 'a describe_args) -> t.output) (option string);
    ]

let pp_action pp_a ppf = function
  | Configure c -> Fmt.pf ppf "@[configure:@ @[<2>%a@]@]" (pp_configure pp_a) c
  | Query q -> Fmt.pf ppf "@[query:@ @[<2>%a@]@]" (pp_query pp_a) q
  | Describe d -> Fmt.pf ppf "@[describe:@ @[<2>%a@]@]" (pp_describe pp_a) d
  | Build b -> Fmt.pf ppf "@[build:@ @[<2>%a@]@]" pp_a b
  | Clean c -> Fmt.pf ppf "@[clean:@ @[<2>%a@]@]" pp_a c
  | Help -> Fmt.string ppf "help"

let setup =
  Term.(
    const (fun () _ _ _ -> ()) $ setup_log $ config_file $ build_dir $ dry_run)

(*
 * Subcommand specifications
 *)

module Subcommands = struct
  (** The 'configure' subcommand *)
  let configure result =
    ( Term.(
        const (fun _ output result -> Configure { output; result })
        $ setup
        $ output
        $ result),
      Term.info "configure" ~doc:"Configure a $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,configure) command initializes a fresh $(mname) \
               application.";
          ] )

  let query result =
    ( Term.(
        const (fun _ kind result -> Query { kind; result })
        $ setup
        $ kind
        $ result),
      Term.info "query" ~doc:"Query information about the $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,query) command queries information about the $(mname) \
               application.";
          ] )

  (** The 'describe' subcommand *)
  let describe result =
    ( Term.(
        const (fun _ _ result output dotcmd dot ->
            Describe { result; dotcmd; dot; output })
        $ setup
        $ full_eval
        $ result
        $ output
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
  let build result =
    let doc = "Build a $(mname) application." in
    ( Term.(const (fun _ result -> Build result) $ setup $ result),
      Term.info "build" ~doc ~man:[ `S "DESCRIPTION"; `P doc ] )

  (** The 'clean' subcommand *)
  let clean result =
    let doc = "Clean the files produced by $(mname) for a given application." in
    ( Term.(const (fun _ result -> Clean result) $ setup $ result),
      Term.info "clean" ~doc ~man:[ `S "DESCRIPTION"; `P doc ] )

  (** The 'help' subcommand *)
  let help base_context =
    let topic =
      let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
      Arg.(value & pos 0 (some string) None & doc)
    in
    let help man_format cmds topic _keys =
      match topic with
      | None -> `Help (`Pager, None)
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
        const (fun _ _ () -> Help)
        $ setup
        $ output
        $ ret
            ( const help
            $ Term.man_format
            $ Term.choice_names
            $ topic
            $ base_context )),
      Term.info "help" ~doc:"Display help about $(mname) commands."
        ~man:
          [
            `S "DESCRIPTION";
            `P "Prints help.";
            `P "Use `$(mname) help topics' to get the full list of help topics.";
          ] )

  let default ~name ~version =
    let usage = `Help (`Plain, None) in
    ( Term.(ret (pure usage) $ setup),
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
let read_full_eval : string array -> bool option =
 fun argv ->
  match Term.eval_peek_opts ~argv full_eval with _, `Ok b -> b | _ -> None

let parse_args ?help_ppf ?err_ppf ~name ~version ~configure ~query ~describe
    ~build ~clean ~help argv =
  Cmdliner.Term.eval_choice ?help:help_ppf ?err:err_ppf ~argv ~catch:false
    (Subcommands.default ~name ~version)
    [
      Subcommands.configure configure;
      Subcommands.describe describe;
      Subcommands.query query;
      Subcommands.build build;
      Subcommands.clean clean;
      Subcommands.help help;
    ]
