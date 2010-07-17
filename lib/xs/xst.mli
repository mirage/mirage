type ops = {
  directory : string -> string list Lwt.t;
  read : string -> string Lwt.t;
  readv : string -> string list -> string Lwt.t list;
  write : string -> string -> unit Lwt.t;
  writev : string -> (string * string) list -> unit Lwt.t;
  mkdir : string -> unit Lwt.t;
  rm : string -> unit Lwt.t;
  getperms : string -> Xsraw.perms Lwt.t;
  setperms : string -> Xsraw.perms -> unit Lwt.t;
  setpermsv : string -> string list -> Xsraw.perms -> unit Lwt.t;
}
val get_operations : int -> Xsraw.con -> ops
val transaction : Xsraw.con -> (ops -> 'a) -> 'a Lwt.t
