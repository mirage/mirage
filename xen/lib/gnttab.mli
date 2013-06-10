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

(** {2 Receiving foreign pages}
    This API should be in sync with the xenctrl 'gntdev' one. *)

type interface
(** A connection to the grant device, needed for mapping/unmapping. *)

val interface_open: unit -> interface
(** Open a connection to the grant device. This must be done before any
    calls to map or unmap. *)

val interface_close: interface -> unit
(** Close a connection to the grant device. Any future calls to map or
    unmap will fail. *)

type grant_table_index
(** Abstract type of grant table index. *)

val grant_table_index_of_int32: int32 -> grant_table_index
val int32_of_grant_table_index: grant_table_index -> int32
val string_of_grant_table_index: grant_table_index -> string
val grant_table_index_of_string: string -> grant_table_index

val console: grant_table_index
(** In xen-4.2 and later, the domain builder will allocate one of the
	reserved grant table entries and use it to pre-authorise the console
	backend domain. *)

val xenstore: grant_table_index
(** In xen-4.2 and later, the domain builder will allocate one of the
	reserved grant table entries and use it to pre-authorise the xenstore
	backend domain. *)

type grant = {
    domid: int;
      (** foreign domain who is exporting memory *)
    ref: grant_table_index;
      (** id which identifies the specific export in the foreign domain *)
}
(** A foreign domain must explicitly "grant" us memory and send us the
    "reference". The pair of (foreign domain id, reference) uniquely
    identifies the block of memory. This pair ("grant") is transmitted
    to us out-of-band, usually either via xenstore during device setup or
    via a shared memory ring structure. *)

type permission =
| RO  (** contents may only be read *)
| RW  (** contents may be read and written *)
(** Permissions associated with each mapping. *)

module Local_mapping : sig 
  type t
  (** Abstract type representing a locally-mapped shared memory page *)

  val to_buf: t -> Io_page.t
end 

val map: interface -> grant -> permission -> Local_mapping.t option
(** Create a single mapping from a grant using a given list of permissions.
    On error this function returns None. *)

val mapv: interface -> grant list -> permission -> Local_mapping.t option
(** Create a single contiguous mapping from a list of grants using a common
    list of permissions. Note the grant list can involve grants from multiple
    domains. On error this function returns None. *)

val unmap_exn: interface -> Local_mapping.t -> unit 
(** Attempt to unmap a local mapping. Throws a Failure exception if
    unsuccessful. *)


(** {2 Offering pages to foreign domains}
    This API *should* be in sync with the xenctrl 'gntshr' one but
    it currently isn't because 'gntshr' doesn't seem to offer the
    ability to export already allocated memory. *)

val put : grant_table_index -> unit
val get : unit -> grant_table_index Lwt.t
val get_n : int -> grant_table_index list Lwt.t

val num_free_grants : unit -> int

val with_ref: (grant_table_index -> 'a Lwt.t) -> 'a Lwt.t
val with_refs: int -> (grant_table_index list -> 'a Lwt.t) -> 'a Lwt.t

val grant_access : domid:int -> perm:permission -> grant_table_index -> Io_page.t -> unit
val end_access : grant_table_index -> unit
val with_grant : domid:int -> perm:permission -> grant_table_index -> Io_page.t -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val with_grants : domid:int -> perm:permission -> grant_table_index list -> Io_page.t list -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val with_mapping : interface -> int -> int32 -> permission -> (Local_mapping.t option -> 'a Lwt.t) -> 'a Lwt.t


val suspend : unit -> unit
val resume : unit -> unit

