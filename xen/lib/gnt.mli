(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

(** Allow a local xen domain to read/write memory exported ("granted")
    from foreign domains. Safe memory sharing is a building block of all
    xen inter-domain communication protocols such as those for virtual
    network and disk devices.

    Foreign domains will explicitly "grant" us access to certain memory
    regions such as disk buffers. These regions are uniquely identified
    by the pair of (foreign domain id, integer reference) which is
    passed to us over some existing channel (typically via xenstore keys
    or via structures in previously-shared memory region).
*)

(** {2 Common interface} *)

type gntref = int
(** Type of a grant table index, called a grant reference in
    Xen's terminology. *)

(** {2 Receiving foreign pages} *)

module Gnttab : sig
  type interface
  (** A connection to the grant device, needed for mapping/unmapping. *)

  val interface_open: unit -> interface
  (** Open a connection to the grant device. This must be done before any
      calls to map or unmap. *)

  val interface_close: interface -> unit
  (** Close a connection to the grant device. Any future calls to map or
      unmap will fail. *)

  type grant = {
    domid: int;
    (** foreign domain who is exporting memory *)
    ref: gntref;
    (** id which identifies the specific export in the foreign domain *)
  }
  (** A foreign domain must explicitly "grant" us memory and send us the
      "reference". The pair of (foreign domain id, reference) uniquely
      identifies the block of memory. This pair ("grant") is transmitted
      to us out-of-band, usually either via xenstore during device setup or
      via a shared memory ring structure. *)

  module Local_mapping : sig
    type t
    (** Abstract type representing locally-mapped shared memory
        pages. *)

    val to_buf : t -> Io_page.t
  end

  val map_exn : interface -> grant -> bool -> Local_mapping.t
  (** [map_exn if grant writeable] creates a single mapping from a grant
      using that will be writeable if [writeable] is [true]. *)

  val map : interface -> grant -> bool -> Local_mapping.t option
  (** Like the above but return an option instead of raising an
      exception. *)

  val mapv_exn : interface -> grant list -> bool -> Local_mapping.t
  (** [mapv_exn if grants writeable] creates a single contiguous
      mapping from a list of grants that will be writeable if
      [writeable] is [true]. Note the grant list can involve grants
      from multiple domains. If the mapping fails (because at least
      one grant fails to be mapped), then all grants are unmapped. *)

  val mapv: interface -> grant list -> bool -> Local_mapping.t option
  (** Like the above but return an option instead of raising an
      exception. *)

  val unmap_exn: interface -> Local_mapping.t -> unit
  (** Attempt to unmap a local mapping. Throws a Failure exception if
      unsuccessful. *)

  (** {2 Xen specific functions} *)

  val with_mapping : interface -> grant -> bool ->
    (Local_mapping.t option -> 'a Lwt.t) -> 'a Lwt.t
  (** [with_mapping if grant writeable f] maps [grant] and calls [f] on
      the result. *)
end

(** {2 Offering pages to foreign domains} *)

module Gntshr : sig
  type interface
  (** A connection to the grant device, needed for mapping/unmapping. *)

  val interface_open: unit -> interface
  (** Open a connection to the grant device. This must be done before any
      calls to map or unmap. *)

  val interface_close: interface -> unit
  (** Close a connection to the grant device. Any future calls to map or
      unmap will fail. *)

  type share = {
    refs: gntref list;
    (** List of grant references which have been shared with a foreign
        domain. *)
    mapping: Io_page.t;
    (** Mapping of the shared memory. *)
	}
  (** When sharing a number of pages with another domain, we receive
      back both the list of grant references shared and actually
      mapped page(s). The foreign domain can map the same shared
      memory, after being notified (e.g. via xenstore) of our domid
      and list of references. *)

  val share_pages_exn: interface -> int -> int -> bool -> share
  (** [share_pages_exn if domid count writeable] shares [count] pages
      with foreign domain [domid]. [writeable] determines whether or
      not the foreign domain can write to the shared memory. *)

  val share_pages: interface -> int -> int -> bool -> share option
  (** [share_pages if domid count writeable] shares [count] pages with
      foreign domain [domid]. [writeable] determines whether or not
      the foreign domain can write to the shared memory. On error
      this function returns None. Diagnostic details will be
      logged. *)

  val munmap_exn : interface -> share -> unit
  (** Unmap a single mapping (which may involve multiple grants) *)

  (** {2 Xen specific functions} *)

  val put : gntref -> unit

  val get : unit -> gntref Lwt.t
  val get_n : int -> gntref list Lwt.t

  val get_nonblock : unit -> gntref option
  (** [get_nonblock ()] is [Some idx] is the grant table is not full,
      or [None] otherwise. *)

  val get_n_nonblock : int -> gntref list
  (** [get_n_nonblock count] is a list of grant table indices of
      length [count], or [[]] if there if the table is too full to
      accomodate [count] new grant references. *)

  val num_free_grants : unit -> int

  val with_ref: (gntref -> 'a Lwt.t) -> 'a Lwt.t
  val with_refs: int -> (gntref list -> 'a Lwt.t) -> 'a Lwt.t

  val grant_access : domid:int -> writeable:bool -> gntref -> Io_page.t -> unit
  (** [grant_access ~domid ~writeable gntref page] adds a grant table
      entry at index [gntref] to the grant table, granting access to
      [domid] to read [page], and write to is as well if [writeable] is
      [true]. *)

  val end_access : gntref -> unit
  (** [end_access gntref] removes entry index [gntref] from the grant
      table. *)

  val with_grant : domid:int -> writeable:bool -> gntref ->
    Io_page.t -> (unit -> 'a Lwt.t) -> 'a Lwt.t

  val with_grants : domid:int -> writeable:bool -> gntref list ->
    Io_page.t list -> (unit -> 'a Lwt.t) -> 'a Lwt.t

end

(** {2 Xen specific functions} *)

val console: gntref
(** In xen-4.2 and later, the domain builder will allocate one of the
	  reserved grant table entries and use it to pre-authorise the console
	  backend domain. *)

val xenstore: gntref
(** In xen-4.2 and later, the domain builder will allocate one of the
	  reserved grant table entries and use it to pre-authorise the xenstore
	  backend domain. *)

(** Functions called by [Sched], do not call directly. *)

val suspend : unit -> unit
val resume : unit -> unit

