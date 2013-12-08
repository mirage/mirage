module V1 = struct

  exception Driver_initialisation_error of string

  (** Useful specialisation for some Mirage types. *)

  open V1

  module type NETWORK= NETWORK
    with type 'a io = 'a Lwt.t
     and type page_aligned_buffer = Cstruct.t

  module type KV_RO = KV_RO
    with type id = unit
     and type 'a io = 'a Lwt.t
     and type page_aligned_buffer = Cstruct.t
    (** KV RO *)

  module type CONSOLE = CONSOLE
    with type 'a io = 'a Lwt.t
    (** Consoles *)

  module type BLOCK = BLOCK
    with type 'a io = 'a Lwt.t
    (** Block devices *)

  module type FS = FS
    with type 'a io = 'a Lwt.t
    (** FS *)

end
