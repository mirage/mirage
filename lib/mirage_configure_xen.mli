open Rresult

module Substitutions : sig
  type v =
    | Name
    | Kernel
    | Memory
    | Block of Mirage_impl_block.block_t
    | Network of string

  type t = (v * string) list

  val lookup : t -> v -> string
  val defaults : Functoria.Info.t -> t
end

val configure_main_xl : ?substitutions:Substitutions.t -> ext:string -> Functoria.Info.t -> (unit, [> R.msg ]) result
val clean_main_xl : name:string -> ext:string -> (unit, [> R.msg ]) result

val clean_main_xe : name:string -> (unit, [> R.msg ]) result
