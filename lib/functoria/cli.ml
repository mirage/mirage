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

let query_section = "QUERY OPTIONS"

let description_section = "DESCRIBE OPTIONS"

type query_kind =
  [ `Name
  | `Packages
  | `Opam
  | `Files
  | `Dune of [ `Base | `Full | `Project | `Workspace ]
  | `Makefile ]

let query_kinds : (string * query_kind) list =
  [
    ("name", `Name);
    ("packages", `Packages);
    ("opam", `Opam);
    ("files", `Files);
    ("Makefile", `Makefile);
    ("dune-base", `Dune `Base);
    ("dune", `Dune `Full);
    ("dune-project", `Dune `Project);
    ("dune-workspace", `Dune `Workspace);
  ]

let setup ~with_setup =
  Term.(
    const snd
    $ with_used_args
        ( const (if with_setup then setup_log else fun _ _ -> ())
        $ Fmt_cli.style_renderer ~docs:common_section ()
        $ Logs_cli.level ~docs:common_section () ))

let config_file =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The configuration file to use."
      [ "f"; "file"; "config-file" ]
  in
  Term.(const Fpath.v $ Arg.(value & opt string "config.ml" & doc))

let map_default ~default f x = if x == default then None else Some (f x)

let context_file =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The context file to use." [ "context-file" ]
  in
  let default = "$(mname).context" in
  Term.(
    const (map_default ~default Fpath.v)
    $ Arg.(value & opt string default & doc))

let dry_run =
  let doc =
    Arg.info ~docs:configuration_section
      ~doc:"Display I/O actions instead of executing them." [ "dry-run" ]
  in
  Arg.(value & flag doc)

(** * Argument specifications *)

(** Argument specification for --depext *)
let depext section =
  let depext_doc =
    Arg.info ~docs:section [ "depext" ]
      ~doc:"Enable call to `opam depext' in the project Makefile."
  in
  let no_depext_doc =
    Arg.info ~docs:section [ "no-depext" ]
      ~doc:"Disable call to `opam depext' in the project Makefile."
  in
  let eval_opts = [ (true, depext_doc); (false, no_depext_doc) ] in
  Arg.(value & vflag true eval_opts)

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
  let enums = Arg.doc_alts_enum ~quoted:true query_kinds in
  let doc =
    Arg.info ~docs:configuration_section ~docv:"INFO" []
      ~doc:(Fmt.strf "The information to query. $(docv) must be %s" enums)
  in
  Arg.(value & pos 0 (enum query_kinds) `Packages & doc)

type 'a args = {
  context : 'a;
  config_file : Fpath.t;
  context_file : Fpath.t option;
  output : string option;
  dry_run : bool;
  setup : string list;
}

let argv_of_args t =
  let config_file =
    match Fpath.to_string t.config_file with
    | "config.ml" -> [||]
    | f -> [| "--config-file"; f |]
  in
  let context_file =
    match t.context_file with
    | None -> [||]
    | Some f -> [| "--context-file"; Fpath.to_string f |]
  in
  let output = match t.output with None -> [||] | Some f -> [| "-o"; f |] in
  let dry_run =
    match t.dry_run with false -> [||] | true -> [| "--dry-run" |]
  in
  let setup = Array.of_list t.setup in
  Array.concat [ config_file; context_file; output; dry_run; setup ]

type 'a configure_args = { args : 'a args; depext : bool }

type 'a build_args = 'a args

type 'a clean_args = 'a args

type 'a help_args = 'a args

type 'a describe_args = {
  args : 'a args;
  dotcmd : string;
  dot : bool;
  eval : bool option;
}

type 'a query_args = { args : 'a args; kind : query_kind; depext : bool }

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
      field "context" (fun (t : 'a args) -> t.context) pp_a;
      field "config_file" (fun t -> t.config_file) Fpath.pp;
      field "output" (fun t -> t.output) (option string);
      field "dry_run" (fun t -> t.dry_run) Fmt.bool;
      field "setup" (fun t -> t.setup) (list string);
    ]

let pp_configure pp_a =
  let open Fmt.Dump in
  record
    [
      field "args" (fun (t : 'a configure_args) -> t.args) (pp_args pp_a);
      field "depext" (fun (t : 'a configure_args) -> t.depext) Fmt.bool;
    ]

let pp_build = pp_args

let pp_clean = pp_args

let pp_help = pp_args

let pp_query_kind ppf (q : query_kind) =
  let rec aux = function
    | [] -> invalid_arg "missing query kind!"
    | (a, b) :: t -> if b = q then Fmt.string ppf a else aux t
  in
  aux query_kinds

let pp_query pp_a =
  let open Fmt.Dump in
  record
    [
      field "args" (fun (t : 'a query_args) -> t.args) (pp_args pp_a);
      field "kind" (fun t -> t.kind) pp_query_kind;
      field "depext" (fun t -> t.depext) Fmt.bool;
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
    const (fun setup config_file context_file dry_run output context ->
        { setup; config_file; context_file; dry_run; output; context })
    $ setup ~with_setup
    $ config_file
    $ context_file
    $ dry_run
    $ output
    $ context)

(*
 * Subcommand specifications
 *)

module Subcommands = struct
  (** The 'configure' subcommand *)
  let configure ~with_setup context =
    ( Term.(
        const (fun args depext -> Configure { args; depext })
        $ args ~with_setup context
        $ depext configuration_section),
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
        const (fun kind args depext -> Query { kind; args; depext })
        $ kind
        $ args ~with_setup context
        $ depext query_section),
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
        const (fun args _ _ () -> Help args)
        $ args ~with_setup context
        $ depext configuration_section
        $ full_eval
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
  | Configure { args; _ } -> args
  | Build x | Clean x | Help x -> x
  | Query { args; _ } -> args
  | Describe { args; _ } -> args

let choices =
  [
    ("configure", `Configure);
    ("build", `Build);
    ("clean", `Clean);
    ("query", `Query);
    ("describe", `Describe);
    ("help", `Help);
  ]

let find_choices s =
  List.find_all (fun (k, _) -> Astring.String.is_prefix ~affix:s k) choices

let find_kind s =
  List.find_all (fun (k, _) -> Astring.String.is_prefix ~affix:s k) query_kinds

let next_pos_arg argv i =
  let rec aux i =
    if i >= Array.length argv then None
    else if argv.(i) = "" then aux (i + 1)
    else if argv.(i).[0] = '-' then aux (i + 1)
    else Some i
  in
  aux i

let remove_argv argv i =
  let a = Array.sub argv 0 i in
  let b = Array.sub argv (i + 1) (Array.length argv - i - 1) in
  Array.append a b

let rec find_next_kind argv i =
  match next_pos_arg argv i with
  | None -> (None, argv)
  | Some i -> (
      match find_kind argv.(i) with
      | [] -> find_next_kind argv (i + 1)
      | _ :: _ :: _ as cs ->
          Fmt.invalid_arg "ambiguous sub-command: %a\n%!"
            Fmt.Dump.(list string)
            (List.map fst cs)
      | [ (_, k) ] -> (Some k, remove_argv argv i) )

let rec find_next_choice argv i =
  match next_pos_arg argv i with
  | None -> (None, argv)
  | Some i -> (
      match find_choices argv.(i) with
      | [] -> find_next_choice argv (i + 1)
      | _ :: _ :: _ as cs ->
          Fmt.invalid_arg "ambiguous sub-command: %a\n%!"
            Fmt.Dump.(list string)
            (List.map fst cs)
      | [ (_, a) ] -> (
          match a with
          | (`Configure | `Build | `Clean | `Describe | `Help) as c ->
              (Some c, remove_argv argv i)
          | `Query ->
              let k, argv = find_next_kind argv (i + 1) in
              (Some (`Query k), remove_argv argv i) ) )

let peek_choice argv =
  try match find_next_choice argv 1 with Some c, _ -> `Ok c | _ -> `Default
  with Invalid_argument _ -> `Error `Parse

type 'a result =
  [ `Ok of 'a action | `Error of 'a args * [ `Exn | `Parse | `Term ] | `Version ]

let peek ?(with_setup = false) argv : unit result =
  let niet = Term.pure () in
  let peek t =
    match Term.eval_peek_opts ~argv ~version_opt:true (fst t) with
    | _, `Version -> `Version
    | _, `Error e -> `Error (peek_args ~with_setup:false argv, e)
    | _, `Help ->
        let args = peek_args ~with_setup:false argv in
        `Ok (Help args)
    | Some v, _ | _, `Ok v -> `Ok v
  in
  let peek_cmd t = peek (t niet) in
  match peek_choice argv with
  | `Ok `Configure -> peek_cmd (Subcommands.configure ~with_setup)
  | `Ok `Build -> peek_cmd (Subcommands.build ~with_setup)
  | `Ok `Clean -> peek_cmd (Subcommands.clean ~with_setup)
  | `Ok (`Query _) -> peek_cmd (Subcommands.query ~with_setup)
  | `Ok `Describe -> peek_cmd (Subcommands.describe ~with_setup)
  | `Ok `Help -> peek_cmd (Subcommands.help ~with_setup)
  | `Default ->
      peek (Subcommands.default ~with_setup ~name:"<name>" ~version:"<version>")
  | `Error e -> `Error (peek_args argv, e)
