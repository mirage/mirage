(** [cc to opt] modules is an {i ocamlifier} of a {i cc}/{i ld} command-line.

    The goal of this module is to do a predictible translation from a {i cc}/{i ld}
    command-line to an {i ocamlopt} command-line. It converts:
    {ul
    {- [-l] option to [-cclib -l] option}
    {- [-L] option to [-I] option}}

    Due to the pervasive and versatile context of the linker, it could be hard to
    follow which static libraries will be linked with our {i unikernel}. This module,
    while it formats options, resolves absolute path of static libraries - and checks
    if they exist. Then, it re-order options to ensure absolute path of libraries
    (when -L takes the precedences over -l).

    Into details, this module eats [pkg-config] outputs to give a well-formed
    command-line to {i ocamlopt} and link the {i unikernel} with right static
    libraries according the target.

    Format of [-l] follows description given by {i ld} (which differs, a bit,
    from {i gcc}). Any [-I] option given to {i ocamlopt} is automaticaly translated
    to [-L] by {i ocamlopt} itself. *)

val run_with_binary : string array -> (string list, [> `Msg of string ]) result
val run : ?binary:string -> string array -> (string list, [> `Msg of string ]) result
