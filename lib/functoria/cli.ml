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
  | `Dune of [ `Config | `Build | `Project | `Workspace | `Dist ]
  | `Makefile ]

let query_kinds : (string * query_kind) list =
  [
    ("name", `Name);
    ("packages", `Packages);
    ("opam", `Opam);
    ("files", `Files);
    ("Makefile", `Makefile);
    ("dune.config", `Dune `Config);
    ("dune.build", `Dune `Build);
    ("dune-project", `Dune `Project);
    ("dune-workspace", `Dune `Workspace);
    ("dune.dist", `Dune `Dist);
  ]

let setup ~with_setup =
  Term.(
    const (if with_setup then setup_log else fun _ _ -> ())
    $ Fmt_cli.style_renderer ~docs:common_section ()
    $ Logs_cli.level ~docs:common_section ())

let config_file =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The configuration file to use."
      [ "f"; "file"; "config-file" ]
  in
  Term.(const Fpath.v $ Arg.(value & opt string "config.ml" & doc))

let map_default ~default f x = if x == default then None else Some (f x)

let context_file mname =
  let doc =
    Arg.info ~docs:configuration_section ~docv:"FILE"
      ~doc:"The context file to use." [ "context-file" ]
  in
  let default = mname ^ ".context" in
  Term.(
    const (map_default ~default Fpath.v)
    $ Arg.(value & opt string default & doc))

let extra_repos doc_section =
  let key =
    let parser str =
      match Astring.String.cut ~sep:":" str with
      | Some (name, repository) -> Ok (name, repository)
      | None ->
          Rresult.R.error_msgf
            "Invalid extra repository argument (expected <name>:<repository>)"
    in
    let pp ppf (name, repository) = Fmt.pf ppf "%s:%s" name repository in
    Arg.conv (parser, pp)
  in
  let env = Cmd.Env.info "MIRAGE_EXTRA_REPOS" in
  let doc =
    Arg.info ~docs:doc_section ~docv:"NAME1:URL1,NAME2:URL2,..." ~env
      ~doc:
        "Additional opam-repositories to use when using `opam monorepo lock' \
         to gather local sources. Default: \
         https://github.com/dune-universe/opam-overlays.git & \
         https://github.com/dune-universe/mirage-opam-overlays.git."
      [ "extra-repos" ]
  in
  Arg.(
    value
    & opt (list key)
        [
          ("opam-overlays", "https://github.com/dune-universe/opam-overlays.git");
          ( "mirage-overlays",
            "https://github.com/dune-universe/mirage-opam-overlays.git" );
        ]
    & doc)

let no_extra_repo doc_section =
  let doc =
    Arg.info ~docs:doc_section ~doc:"Disable the use of any overlay repository."
      [ "no-extra-repo" ]
  in
  Arg.(value & flag & doc)

let extra_repos doc_section =
  let ex = extra_repos doc_section in
  let no_ex = no_extra_repo doc_section in
  Term.(const (fun ex no_ex -> if no_ex then [] else ex) $ ex $ no_ex)

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
         the dot file using the  command  given to $(b,--dot-command). Use in \
         combination with $(b,--output=-) (short version: $(b,-o-)) to display \
         the dot file on stdout."
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
      ~doc:(Fmt.str "The information to query. $(docv) must be %s" enums)
  in
  Arg.(value & pos 0 (enum query_kinds) `Packages & doc)

type 'a args = {
  context : 'a;
  config_file : Fpath.t;
  context_file : Fpath.t option;
  output : string option;
  dry_run : bool;
}

let default_args =
  {
    context = ();
    config_file = Fpath.v "dummy";
    context_file = None;
    output = None;
    dry_run = false;
  }

type 'a configure_args = {
  args : 'a args;
  depext : bool;
  extra_repo : (string * string) list;
}

type 'a build_args = 'a args
type 'a clean_args = 'a args
type 'a help_args = 'a args

type 'a describe_args = {
  args : 'a args;
  dotcmd : string;
  dot : bool;
  eval : bool option;
}

type 'a query_args = {
  args : 'a args;
  kind : query_kind;
  depext : bool;
  extra_repo : (string * string) list;
}

type 'a action =
  | Configure of 'a configure_args
  | Query of 'a query_args
  | Describe of 'a describe_args
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
    ]

let pp_configure pp_a =
  let open Fmt.Dump in
  record
    [
      field "args" (fun (t : 'a configure_args) -> t.args) (pp_args pp_a);
      field "depext" (fun (t : 'a configure_args) -> t.depext) Fmt.bool;
    ]

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
  | Clean c -> Fmt.pf ppf "@[clean:@ @[<2>%a@]@]" (pp_clean pp_a) c
  | Help h -> Fmt.pf ppf "@[help:@ @[<2>%a@]@]" (pp_help pp_a) h

(*
 * Subcommand specifications
 *)

module Subcommands = struct
  type 'a t = { with_setup : bool; mname : string; context : 'a Term.t }

  module T = struct
    let args { with_setup; context; mname } =
      Term.(
        const (fun () config_file context_file dry_run output context ->
            { config_file; context_file; dry_run; output; context })
        $ setup ~with_setup
        $ config_file
        $ context_file mname
        $ dry_run
        $ output
        $ context)
  end

  (** The 'configure' subcommand *)
  let configure t =
    ( Term.(
        const (fun args depext extra_repo ->
            Configure { args; depext; extra_repo })
        $ T.args t
        $ depext configuration_section
        $ extra_repos configuration_section),
      Cmd.info "configure" ~doc:"Configure a $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,configure) command initializes a fresh $(mname) \
               application.";
          ] )

  let query t =
    ( Term.(
        const (fun kind args depext extra_repo ->
            Query { kind; args; depext; extra_repo })
        $ kind
        $ T.args t
        $ depext query_section
        $ extra_repos query_section),
      Cmd.info "query" ~doc:"Query information about the $(mname) application."
        ~man:
          [
            `S "DESCRIPTION";
            `P
              "The $(b,query) command queries information about the $(mname) \
               application.";
          ] )

  (** The 'describe' subcommand *)
  let describe t =
    ( Term.(
        const (fun args eval dotcmd dot -> Describe { args; eval; dotcmd; dot })
        $ T.args t
        $ full_eval
        $ dotcmd
        $ dot),
      Cmd.info "describe" ~doc:"Describe a $(mname) application."
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

  (** The 'clean' subcommand *)
  let clean t =
    let doc = "Clean the files produced by $(mname) for a given application." in
    ( Term.(const (fun args -> Clean args) $ T.args t),
      Cmd.info "clean" ~doc ~man:[ `S "DESCRIPTION"; `P doc ] )

  (** The 'help' subcommand *)
  let help t =
    let topic =
      let doc = Arg.info [] ~docv:"TOPIC" ~doc:"The topic to get help on." in
      Arg.(value & pos 0 (some string) None & doc)
    in
    let help man_format cmds topic =
      match topic with
      | None -> `Help (man_format, None)
      | Some topic -> (
          let parser =
            Arg.conv_parser
              (Arg.enum (List.rev_map (fun s -> (s, s)) ("topics" :: cmds)))
          in
          match parser topic with
          | Error (`Msg e) -> `Error (false, e)
          | Ok t when t = "topics" ->
              List.iter print_endline cmds;
              `Ok ()
          | Ok t -> `Help (man_format, Some t))
    in
    ( Term.(
        const (fun args _ _ _ () -> Help args)
        $ T.args t
        $ depext configuration_section
        $ extra_repos configuration_section
        $ full_eval
        $ ret (const help $ Arg.man_format $ Term.choice_names $ topic)),
      Cmd.info "help" ~doc:"Display help about $(mname) commands."
        ~man:
          [
            `S "DESCRIPTION";
            `P "Prints help.";
            `P "Use `$(mname) help topics' to get the full list of help topics.";
          ] )

  let default ~with_setup ~name ~version =
    let usage = `Help (`Plain, None) in
    ( Term.(ret (const usage) $ setup ~with_setup),
      Cmd.info name ~version ~doc:"The $(mname) application builder"
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
  match Cmd.eval_peek_opts ~argv full_eval with _, Ok (`Ok b) -> b | _ -> None

let peek_output argv =
  match Cmd.eval_peek_opts ~argv output with _, Ok (`Ok b) -> b | _ -> None

let peek_args ?(with_setup = false) ~mname argv =
  let args =
    Subcommands.T.args { with_setup; mname; context = Term.const () }
  in
  match Cmd.eval_peek_opts ~argv args with
  | _, Ok (`Ok b) | Some b, _ -> Some b
  | _ -> None

let eval ?(with_setup = true) ?help_ppf ?err_ppf ~name ~version ~configure
    ~query ~describe ~clean ~help ~mname argv =
  let default, info = Subcommands.default ~with_setup ~name ~version in
  let args context = { Subcommands.with_setup; mname; context } in
  let group =
    Cmd.group ~default info
      (List.map
         (fun (term, info) -> Cmd.v info term)
         [
           Subcommands.configure (args configure);
           Subcommands.describe (args describe);
           Subcommands.query (args query);
           Subcommands.clean (args clean);
           Subcommands.help (args help);
         ])
  in
  match Cmd.eval_value ?help:help_ppf ?err:err_ppf ~argv ~catch:false group with
  | Ok (#Cmd.eval_ok as v) -> v
  | Error (#Cmd.eval_error as e) -> `Error e

let args = function
  | Configure { args; _ } -> args
  | Clean x | Help x -> x
  | Query { args; _ } -> args
  | Describe { args; _ } -> args

let choices =
  [
    ("configure", `Configure);
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
      | [ (_, k) ] -> (Some k, remove_argv argv i))

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
          | (`Configure | `Clean | `Describe | `Help) as c ->
              (Some c, remove_argv argv i)
          | `Query ->
              let k, argv = find_next_kind argv (i + 1) in
              (Some (`Query k), remove_argv argv i)))

let peek_choice argv =
  try match find_next_choice argv 1 with Some c, _ -> `Ok c | _ -> `Default
  with Invalid_argument _ -> `Error `Parse

type 'a result =
  [ `Ok of 'a action
  | `Error of 'a args option * [ `Exn | `Parse | `Term ]
  | `Version ]

let peek ?(with_setup = false) ~mname argv : unit result =
  let niet = Term.const () in
  let peek t =
    match Cmd.eval_peek_opts ~argv ~version_opt:true (fst t) with
    | _, Ok `Version -> `Version
    | _, Error e -> `Error (peek_args ~mname argv, e)
    | _, Ok `Help -> (
        let args = peek_args ~with_setup:false ~mname argv in
        match args with
        | Some args -> `Ok (Help args)
        | _ -> `Error (None, `Parse))
    | Some v, _ | _, Ok (`Ok v) -> `Ok v
  in
  let peek_cmd f =
    let args = { Subcommands.with_setup; mname; context = niet } in
    peek (f args)
  in
  match peek_choice argv with
  | `Ok `Configure -> peek_cmd Subcommands.configure
  | `Ok `Clean -> peek_cmd Subcommands.clean
  | `Ok (`Query _) -> peek_cmd Subcommands.query
  | `Ok `Describe -> peek_cmd Subcommands.describe
  | `Ok `Help -> peek_cmd Subcommands.help
  | `Default ->
      peek (Subcommands.default ~with_setup ~name:"<name>" ~version:"<version>")
  | `Error e -> `Error (peek_args ~mname argv, e)
