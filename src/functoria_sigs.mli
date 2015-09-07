module type KEY = sig

  type 'a key
  type 'a value

  type t = Any : 'a key -> t

  module Set : Set.S with type elt = t

end


module type DSL = sig

  (** {2 Module combinators} *)

  type 'a typ
  (** The type of values representing module types. *)

  val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
  (** Construct a functor type from a type and an existing functor
      type. This corresponds to prepending a parameter to the list of
      functor parameters. For example,

      {[ kv_ro @-> ip @-> kv_ro ]}

      describes a functor type that accepts two arguments -- a kv_ro and
      an ip device -- and returns a kv_ro.
  *)

  val typ: 'a -> 'a typ
  (** Return the module signature of a given implementation. *)

  type 'a impl
  (** The type of values representing module implementations. *)

  val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
  (** [m $ a] applies the functor [m] to the module [a]. *)

  (** {2 Key usage} *)

  module Key : KEY

  val if_impl : bool Key.value -> 'a impl -> 'a impl -> 'a impl
  (** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and [impl2] otherwise. *)

  val switch :
    default:'a impl ->
    ('b * 'a impl) list ->
    'b Key.value ->
    'a impl
  (** [switch ~default l v] choose the implementation in [l] corresponding to the value [v].
      The [default] implementation is chosen if no value match.
  *)

  (** {2 Implementations constructors} *)

  val foreign:
    ?keys:Key.t list ->
    ?libraries:string list ->
    ?packages:string list -> string -> 'a typ -> 'a impl
    (** [foreign name libs packs constr typ] states that the module named
        by [name] has the module type [typ]. If [libs] is set, add the
        given set of ocamlfind libraries to the ones loaded by default. If
        [packages] is set, add the given set of OPAM packages to the ones
        loaded by default. *)

  type job
  (** Type for job values. *)

  val job: job typ
  (** Representation of a job. *)

  (** {2 Configurable} *)

  (** Information available during configuration. *)
  module Info : sig
    type t

    val name : t -> string
    val root : t -> string
    val libraries : t -> Functoria_misc.StringSet.t
    val packages : t -> Functoria_misc.StringSet.t
    val keys : t -> Key.Set.t
  end

  type any_impl = Any : _ impl -> any_impl
  (** Type of an implementation, with it's type variable hidden. *)

  val hide : _ impl -> any_impl
  (** Hide the type variable of an implementation. Useful for dependencies. *)

  (** Signature for configurable devices. *)
  class type ['ty] configurable = object

    method ty : 'ty typ
    (** Type of the device. *)

    method name: string
    (** Return the unique variable name holding the state of the device. *)

    method module_name: string
    (** Return the name of the module implementing the device. *)

    method packages: string list
    (** Return the list of OPAM packages which needs to be installed to
        use the device. *)

    method libraries: string list
    (** Return the list of ocamlfind libraries to link with the
        application to use the device. *)

    method keys: Key.t list
    (** Return the list of keys to configure the device. *)

    method connect : Info.t -> string -> string list -> string
    (** Return the function call to connect at runtime with the device. *)

    method configure: Info.t -> unit
    (** Configure the device. *)

    method clean: Info.t -> unit
    (** Clean all the files generated to use the device. *)

    method dependencies : any_impl list
    (** The list of dependencies that must be initalized before this module. *)

  end

  val impl: 'a configurable -> 'a impl
  (** Extend the library with an external configuration. *)


end
