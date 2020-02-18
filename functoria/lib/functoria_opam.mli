module Package = Functoria_package
module Install = Functoria_install

type t

val v :
  ?build:string list ->
  ?depends:Package.t list ->
  ?pins:(string * string) list ->
  src:[ `Auto | `None | `Some of string ] ->
  string ->
  t

val pp : t Fmt.t
