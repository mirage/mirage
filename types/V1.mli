(*
 * Copyright (c) 2011-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013      Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013      Citrix Systems Inc
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

module type DEVICE = sig
  (** Device operations.
      Defines the functions to connect and disconnect any device *)

  type +'a io
  (** A potentially blocking I/O operation *)

  type t
  (** The type representing the internal state of the device *)

  type error
  (** An error signalled by the device, normally returned after a
      connection attempt *)

  type id
  (** Type defining an identifier for this device that uniquely
      identifies it among a device tree. *)

  val id : t -> id
  (** Return the identifier that was used to construct this device *)

  val connect: id -> [ `Error of error | `Ok of t ] io
  (** Connect to the device identified by [id] *)

  val disconnect : t -> unit io
  (** Disconnect from the device.  While this might take some
      time to complete, it can never result in an error. *)
end

module type TIME = sig
  (** Time operations for cooperative threads. *)

  type +'a io
  (** A potentially blocking I/O operation *)

  val sleep: float -> unit io
  (** [sleep nsec] Block the current thread for [TODO remove float] *)
end

module type RANDOM = sig
  (** Operations to generate entropy.  This is currently a passthrough to
      the OCaml Random generator, and will be deprecated in V2 and turned
      into a proper DEVICE with blocking modes. *)

  val self_init : unit -> unit
  (** Initialize the generator with a random seed chosen in a system-dependent way. *)

  val int : int -> int
  (** [int bound] returns a random integer between 0 (inclusive) and [bound] (exclusive).
     [bound] must be greater than 0 and less than 2{^30}. *)

  val int32 : int32 -> int32
  (** [int32 bound] returns a random integer between 0 (inclusive) and [bound] (exclusive).
      [bound] must be greater than 0. *)
end

module type CLOCK = sig
  (** Clock operations.
      Currently read-only to retrieve the time in various formats. *)

  type tm =
    { tm_sec : int;               (** Seconds 0..60 *)
      tm_min : int;               (** Minutes 0..59 *)
      tm_hour : int;              (** Hours 0..23 *)
      tm_mday : int;              (** Day of month 1..31 *)
      tm_mon : int;               (** Month of year 0..11 *)
      tm_year : int;              (** Year - 1900 *)
      tm_wday : int;              (** Day of week (Sunday is 0) *)
      tm_yday : int;              (** Day of year 0..365 *)
      tm_isdst : bool;            (** Daylight time savings in effect *)
    }
  (** The type representing wallclock time and calendar date. *)

  val time : unit -> float
  (** Return the current time since 00:00:00 GMT, Jan. 1, 1970, in
      seconds. *)

  val gmtime : float -> tm
  (** Convert a time in seconds, as returned by {!time}, into a
      date and a time. Assumes UTC (Coordinated Universal Time), also
      known as GMT. *)
end

module type CONSOLE = sig
  (** Text console input/output operations. *)

  type error = [
    | `Invalid_console of string
  ]
  (** The type representing possible errors when attaching a console. *)

  include DEVICE with
    type error := error

  val write : t -> string -> int -> int -> int
  (** [write t buf off len] writes up to [len] chars of [String.sub buf
      off len] to the console [t] and returns the number of bytes
      written. Raises {!Invalid_argument} if [len > buf - off]. *)

  val write_all : t -> string -> int -> int -> unit io
  (** [write_all t buf off len] is a thread that writes [String.sub buf
      off len] to the console [t] and returns when done. Raises
      {!Invalid_argument} if [len > buf - off]. *)

  val log : t -> string -> unit
  (** [log str] writes as much characters of [str] that can be written
      in one write operation to the console [t], then writes
      "\r\n" to it. *)

  val log_s : t -> string -> unit io
  (** [log_s str] is a thread that writes [str ^ "\r\n"] in the
      console [t]. *)

end

module type BLOCK = sig
  (** Operations on sector-addressible block devices, usually used
      for persistent storage *)

  type page_aligned_buffer
  (** Abstract type for a page-aligned memory buffer *)

  type error = [
    | `Unknown of string (** an undiagnosed error *)
    | `Unimplemented     (** operation not yet implemented in the code *)
    | `Is_read_only      (** you cannot write to a read/only instance *)
    | `Disconnected      (** the device has been previously disconnected *)
  ]
  (** IO operation errors *)


  include DEVICE with
    type error := error

  type info = {
    read_write: bool;    (** True if we can write, false if read/only *)
    sector_size: int;    (** Octets per sector *)
    size_sectors: int64; (** Total sectors per device *)
  }
  (** Characteristics of the block device. Note some devices may be able
      to make themselves bigger over time. *)

  val get_info: t -> info io
  (** Query the characteristics of a specific block device *)

  val read: t -> int64 -> page_aligned_buffer list -> [ `Error of error | `Ok of unit ] io
  (** [read device sector_start buffers] returns a blocking IO operation which
      attempts to fill [buffers] with data starting at [sector_start].
      Each of [buffers] must be a whole number of sectors in length. The list
      of buffers can be of any length. *)

  val write: t -> int64 -> page_aligned_buffer list -> [ `Error of error | `Ok of unit ] io
  (** [write device sector_start buffers] returns a blocking IO operation which
      attempts to write the data contained within [buffers] to [t] starting
      at [sector_start]. When the IO operation completes then all writes have been
      persisted.

      Once submitted, it is not possible to cancel a request and there is no timeout.

      The operation may fail with
      * [`Unimplemented]: the operation has not been implemented, no data has been written
      * [`Is_read_only]: the device is read-only, no data has been written
      * [`Disconnected]: the device has been disconnected at application request,
        an unknown amount of data has been written
      * [`Unknown]: some other permanent, fatal error (e.g. disk is on fire), where
        an unknown amount of data has been written

      Each of [buffers] must be a whole number of sectors in length. The list
      of buffers can be of any length.

      The data will not be copied, so the supplied buffers must not be re-used
      until the IO operation completes. *)

end

module type NETWORK = sig
  (** A network interface that serves Ethernet frames. *)

  type page_aligned_buffer
  (** Abstract type for a page-aligned memory buffer *)

  type buffer
  (** Abstract type for a memory buffer that may not be page aligned *)

  type error = [
    | `Unknown of string (** an undiagnosed error *)
    | `Unimplemented     (** operation not yet implemented in the code *)
    | `Disconnected      (** the device has been previously disconnected *)
  ]
  (** IO operation errors *)

  type macaddr
  (** Unique MAC identifier for the device *)

  include DEVICE with
    type error := error

  val write : t -> buffer -> unit io
  (** [write nf buf] outputs [buf] to netfront [nf]. *)

  val writev : t -> buffer list -> unit io
  (** [writev nf bufs] output a list of buffers to netfront [nf] as a
      single packet. *)

  val listen : t -> (buffer -> unit io) -> unit io
  (** [listen nf fn] is a blocking operation that calls [fn buf] with
      every packet that is read from the interface.  It returns as soon
      as it has initialised, and the function can be stopped by calling
      [disconnect] in the device layer. *)

  val mac : t -> macaddr
  (** [mac nf] is the MAC address of [nf]. *)

  type stats = {
    mutable rx_bytes : int64;
    mutable rx_pkts : int32;
    mutable tx_bytes : int64;
    mutable tx_pkts : int32;
  }
  (** Frame statistics to track the usage of the device. *)

  val get_stats_counters : t -> stats
  (** Obtain the most recent snapshot of the device statistics. *)

  val reset_stats_counters : t -> unit
  (** Reset the statistics associated with this device to their defaults. *)
end

module type ETHIF = sig
  (** An Ethernet stack that parses frames from a network device and
      can associate them with IP address via ARP. *)

  type buffer
  (** Abstract type for a memory buffer that may not be page aligned *)

  type netif
  (** Abstract type for an Ethernet network interface. *)

  type ipv4addr
  (** Abstract type for an IPv4 address representation. *)

  type error = [
    | `Unknown of string (** an undiagnosed error *)
    | `Unimplemented     (** operation not yet implemented in the code *)
    | `Disconnected      (** the device has been previously disconnected *)
  ]
  (** IO operation errors *)

  type macaddr
  (** Unique MAC identifier for the device *)

  include DEVICE with
        type error := error
    and type id    := netif

  val write : t -> buffer -> unit io
  (** [write nf buf] outputs [buf] to netfront [nf]. *)

  val writev : t -> buffer list -> unit io
  (** [writev nf bufs] output a list of buffers to netfront [nf] as a
      single packet. *)

  val mac : t -> macaddr
  (** [mac nf] is the MAC address of [nf]. *)

  val input : ipv4:(buffer -> unit io) -> ipv6:(buffer -> unit io) -> t -> buffer -> unit io
  (** [listen nf fn] is a blocking operation that calls [fn buf] with
      every packet that is read from the interface.  It returns as soon
      as it has initialised, and the function can be stopped by calling
      [disconnect] in the device layer. *)

  val query_arpv4 : t -> ipv4addr -> macaddr io
  (** Query the association from an IPV4 address to a MAC address.
      TODO: clarify if this task is guaranteed to be cancelable or not. *)

  val add_ipv4 : t -> ipv4addr -> unit io
  (** Bind an IPv4 address to this interface, to be used when replying
      to ARPv4 requests. *)
end

module type IPV4 = sig
  (** An IPv4 stack that parses Ethernet frames into IPv4 packets *)

  type buffer
  (** Abstract type for a memory buffer that may not be page aligned *)

  type ethif
  (** Abstract type for an Ethernet device. *)

  type ipv4addr
  (** Abstract type for an IPv4 address. *)

  type error = [
    | `Unknown of string (** an undiagnosed error *)
    | `Unimplemented     (** operation not yet implemented in the code *)
  ]
  (** IO operation errors *)

  include DEVICE with
        type error := error
    and type id    := ethif

  type callback = src:ipv4addr -> dst:ipv4addr -> buffer -> unit io
  (** An input continuation used by the parsing functions to pass on
      an input packet down the stack.
      [callback ~src ~dst buf] will be called with [src] and [dst]
      containing the source and destination IPv4 address respectively,
      and [buf] will be a buffer pointing at the start of the IPv4
      payload. *)

  val input:
    tcp:callback -> udp:callback -> default:(proto:int -> callback) ->
    t -> buffer -> unit io
  (** [input ~tcp ~udp ~default ip buf] demultiplexes an incoming [buffer]
    that contains an IPv4 frame.  It examines the protocol header
    and passes the result onto either the [tcp] or [udp] function, or
    the [default] function for unknown IP protocols. *)

  val allocate_frame:
    proto:[< `ICMP | `TCP | `UDP ] ->
    dest_ip:ipv4addr -> t -> (buffer * int) io
  (** [allocate_frame ~proto ~dest_ip] will an output buffer for the
    [proto] IP protocol for the [dest_ip] IPv4 destination.  It returns
    a tuple of the buffer of the full Ethernet frame (pointing at the
    start of the frame) and the total length of the Ethernet and IPv4
    header that was written.  The caller can create a sub-view
    into the payload using this information if it needs to, or combine
    it with [write] to do a scatter-gather output with an existing
    payload. *)

  val write: t -> buffer -> buffer -> unit io
  (** [write t frame buffer] concatenates a header [frame] (possibly
    allocated with {!allocate_frame} with the [buffer] and outputs it
    as a single frame. *)
 
  val writev: t -> buffer -> buffer list -> unit io 
  (** [writev t frame buffers] concatenates a header [frame] (possibly
    allocated with {!allocate_frame} with the [buffer] list and outputs
    it all as a single frame. Uses the underlying scatter-gather interface
    if available for efficiency. *)

  val set_ipv4: t -> ipv4addr -> unit io
  (** Set the IPv4 address associated with this interface.  Currently
      only supports a single IPv4 address, and aliases will be added in
      a future revision. *)

  val get_ipv4: t -> ipv4addr
  (** Get the IPv4 address associated with this interface.  If none has
      been previously bound via {!set_ipv4}, it defaults to {!Ipaddr.V4.any}. *)

  val set_ipv4_netmask: t -> ipv4addr -> unit io
  (** Set the IPv4 netmask associated with this interface.  Currently
      only supports a single IPv4 netmask, and aliases will be added in
      a future revision. *)

  val get_ipv4_netmask: t -> ipv4addr
  (** Get the IPv4 netmask associated with this interface.  If none has
      been previously bound via {!set_ipv4_netmask}, it defaults to
      {!Ipaddr.V4.any}. *)

  val set_ipv4_gateways: t -> ipv4addr list -> unit io
  (** Set the IPv4 gateways associated with this interface. *)
 
  val get_ipv4_gateways: t -> ipv4addr list
  (** Get the IPv4 gateways associated with this interface.  If none has
      been previously bound via {!set_ipv4_netmask}, it defaults to
      an empty list. *)
end

module type UDPV4 = sig
  (** A UDPv4 stack that can send and receive datagrams. *)

  type buffer
  (** Abstract type for a memory buffer that may not be page aligned. *)

  type ipv4
  (** Abstract type for an IPv4 stack for this stack to connect to. *)

  type ipv4addr
  (** Abstract type for an IPv4 address representation. *)

  type ipv4input
  (** An input function continuation to pass onto the underlying {!ipv4}
      stack.  This will normally be a NOOP for a conventional kernel, but
      a direct implementation will parse the buffer. *)

  type error = [
    | `Unknown of string (** an undiagnosed error *)
  ]
  (** IO operation errors *)

  include DEVICE with
      type error := error
  and type id := ipv4

  type callback = src:ipv4addr -> dst:ipv4addr -> src_port:int -> buffer -> unit io
  (** Callback function that adds the UDPv4 metadata for [src] and [dst] IPv4
      addresses, the [src_port] of the connection and the [buffer] payload 
      of the datagram. *)

  val input: listeners:(dst_port:int -> callback option) -> t -> ipv4input
  (** [input listeners t] demultiplexes incoming datagrams based on their destination
      port.  The [listeners] callback is will either return a concrete handler or
      a [None], which results in the datagram being dropped. *)

  val write: ?source_port:int -> dest_ip:ipv4addr -> dest_port:int -> t -> buffer -> unit io
  (** [write ~source_port ~dest_ip ~dest_port udp data] is a thread that
      writes [data] from an optional [source_port] to a [dest_ip] and [dest_port]
      IPv4 address pair. *)
end

module type TCPV4 = sig
  (** A TCPv4 stack that can send and receive reliable streams using the TCP protocol. *)

  type buffer
  (** Abstract type for a memory buffer that may not be page aligned. *)

  type ipv4
  (** Abstract type for an IPv4 stack for this stack to connect to. *)

  type ipv4addr
  (** Abstract type for an IPv4 address representation. *)

  type ipv4input
  (** An input function continuation to pass onto the underlying {!ipv4}
      stack.  This will normally be a NOOP for a conventional kernel, but
      a direct implementation will parse the buffer. *)

  type flow
  (** A flow represents the state of a single TCPv4 stream that is connected
      to an endpoint. *)

  type error = [
    | `Unknown of string (** an undiagnosed error. *)
    | `Timeout  (** connection attempt did not get a valid response. *)
    | `Refused  (** connection attempt was actively refused via an RST. *)
  ]
  (** IO operation errors *)

  include DEVICE with
      type error := error
  and type id := ipv4

  type callback = flow -> unit io
  (** Application callback that receives a [flow] that it can read/write to. *)

  val get_dest : flow -> ipv4addr * int
  (** Get the destination IPv4 address and destination port that a flow is
      currently connected to. *)

  val read : flow -> [`Ok of buffer | `Eof | `Error of error ] io
  (** [read flow] will block until it either successfully reads a segment
      of data from the current flow, receives an [Eof] signifying that
      the connection is now closed, or an [Error]. *)

  val write : flow -> buffer -> unit io
  (** [write flow buffer] will block until the contents of [buffer] are
      transmitted to the remote endpoint.  The contents may be transmitted
      in separate packets, depending on the underlying transport. *)

  val writev : flow -> buffer list -> unit io
  (** [writev flow buffers] will block until the contents of [buffer list]
      are all successfully transmitted to the remote endpoint. *)

  val write_nodelay : flow -> buffer -> unit io
  (** [write_nodelay flow] will block until the contents of [buffer list]
      are all successfully transmitted to the remote endpoint. Buffering
      within the stack is minimized in this mode.  Note that this API will
      change in a future revision to be a per-flow attribute instead of a
      separately exposed function. *)

  val writev_nodelay : flow -> buffer list -> unit io
  (** [writev_nodelay flow] will block until the contents of [buffer list]
      are all successfully transmitted to the remote endpoint. Buffering
      within the stack is minimized in this mode.  Note that this API will
      change in a future revision to be a per-flow attribute instead of a
      separately exposed function. *)

  val close : flow -> unit io
  (** [close flow] will signal to the remote endpoint that the flow is now
      shutdown.  The caller should not perform any writes after this call. *)

  val create_connection : t -> ipv4addr * int ->
    [ `Ok of flow | `Error of error ] io
  (** [create_connection t (addr,port)] will open a TCPv4 connection to the
      specified endpoint. *)

  val input: t -> listeners:(int -> callback option) -> ipv4input
  (** [input t listeners] defines a mapping of threads that are willing to
      accept new flows on a given port.  If the [callback] returns [None],
      the input function will return an RST to refuse connections on a port. *)
end

module type STACKV4 = sig
  type console
  type netif
  type mode
  type ('console,'netif,'mode) config
  type ipv4addr
  type buffer

  type error = [
    | `Unknown of string
  ]

  include DEVICE with
    type error := error
    and type id = (console,netif,mode) config

  module UDPV4 : UDPV4 with type +'a io = 'a io and type ipv4addr = ipv4addr and type buffer = buffer
  module TCPV4 : TCPV4 with type +'a io = 'a io and type ipv4addr = ipv4addr and type buffer = buffer

  val listen_udpv4 : t -> port:int -> UDPV4.callback -> unit
  val listen_tcpv4 : t -> port:int -> TCPV4.callback -> unit
  val listen : t -> unit io
end

(** Type of a buffered byte-stream network protocol *)
module type CHANNEL = sig
  type buffer
  type flow
  type t

  type +'a io
  type 'a io_stream

  exception Closed

  val create       : flow -> t
  val to_flow      : t -> flow

  val read_char    : t -> char io
  val read_until   : t -> char -> (bool * buffer) io
  val read_some    : ?len:int -> t -> buffer io
  val read_stream  : ?len: int -> t -> buffer io_stream
  val read_line    : t -> buffer list io

  val write_char   : t -> char -> unit
  val write_string : t -> string -> int -> int -> unit
  val write_buffer : t -> buffer -> unit
  val write_line   : t -> string -> unit

  val flush        : t -> unit io
  val close        : t -> unit io

end

module type FS = sig

  (** Abstract type representing an error from the block layer *)
  type block_device_error

  type error = [
    | `Not_a_directory of string             (** Cannot create a directory entry in a file *)
    | `Is_a_directory of string              (** Cannot read or write the contents of a directory *)
    | `Directory_not_empty of string         (** Cannot remove a non-empty directory *)
    | `No_directory_entry of string * string (** Cannot find a directory entry *)
    | `File_already_exists of string         (** Cannot create a file with a duplicate name *)
    | `No_space                              (** No space left on the block device *)
    | `Format_not_recognised of string       (** The block device appears to not be formatted *)
    | `Unknown_error of string
    | `Block_device of block_device_error
  ]

  include DEVICE
    with type error := error

  (** Abstract type for a page-aligned memory buffer *)
  type page_aligned_buffer

  val read: t -> string -> int -> int -> [ `Ok of page_aligned_buffer list | `Error of error ] io
  (** [read t key offset length] reads up to [length] bytes from the value
      associated with [key]. If less data is returned than requested, this
      indicates the end of the value. *)

  val size: t -> string -> [`Error of error | `Ok of int64] io
  (** Get the value size. *)

  (* The following is specific to FS: *)
  (** Per-file/directory statistics *)
  type stat = {
    filename: string; (** Filename within the enclosing directory *)
    read_only: bool;  (** True means the contents are read-only *)
    directory: bool;  (** True means the entity is a directory; false means a file *)
    size: int64;      (** Size of the entity in bytes *)
  }

  (** [format t size] erases the contents of [t] and creates an empty filesystem
      of size [size] bytes *)
  val format: t -> int64 -> [ `Ok of unit | `Error of error ] io

  (** [create t path] creates an empty file at [path] *)
  val create: t -> string -> [ `Ok of unit | `Error of error ] io

  (** [mkdir t path] creates an empty directory at [path] *)
  val mkdir: t -> string -> [ `Ok of unit | `Error of error ] io

  (** [destroy t path] removes a [path] (which may be a file or an empty
      directory) on filesystem [t] *)
  val destroy: t -> string -> [ `Ok of unit | `Error of error ] io

  (** [stat t path] returns information about file or directory at [path] *)
  val stat: t -> string -> [ `Ok of stat | `Error of error ] io

  (** [listdir t path] returns the names of files and subdirectories
      within the directory [path] *)
  val listdir: t -> string -> [ `Ok of string list | `Error of error ] io

  (** [write t path offset data] writes [data] at [offset] in file [path] on
      filesystem [t] *)
  val write: t -> string -> int -> page_aligned_buffer -> [ `Ok of unit | `Error of error ] io

end

module type IO_PAGE = sig
  (** Memory allocation interface. *)

  type buf
  (** Type of a C buffer (usually Cstruct) *)

  type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
  (** Type of memory blocks. *)

  val get : int -> t
  (** [get n] allocates and returns a memory block of [n] pages. If
      there is not enough memory, the unikernel will terminate. *)

  val get_order : int -> t
  (** [get_order i] is [get (1 lsl i)]. *)

  val pages : int -> t list
  (** [pages n] allocates a memory block of [n] pages and return the the
      list of pages allocated. *)

  val pages_order : int -> t list
  (** [pages_order i] is [pages (1 lsl i)]. *)

  val length : t -> int
  (** [length t] is the size of [t], in bytes. *)

  val to_cstruct : t -> buf
  val to_string : t -> string

  val to_pages : t -> t list
  (** [to_pages t] is a list of [size] memory blocks of one page each,
      where [size] is the size of [t] in pages. *)

  val string_blit : string -> int -> t -> int -> int -> unit
  (** [string_blit src srcoff dst dstoff len] copies [len] bytes from
      string [src], starting at byte number [srcoff], to memory block
      [dst], starting at byte number dstoff. *)

  val blit : t -> t -> unit
  (** [blit t1 t2] is the same as {!Bigarray.Array1.blit}. *)

  val round_to_page_size : int -> int
  (** [round_to_page_size n] returns the number of bytes that will be
      allocated for storing [n] bytes in memory *)
end

module type KV_RO = sig
  (** Static Key/value store. *)

  type error =
    | Unknown_key of string

  include DEVICE
    with type error := error

  (** Abstract type for a page-aligned memory buffer *)
  type page_aligned_buffer

  val read: t -> string -> int -> int -> [ `Ok of page_aligned_buffer list | `Error of error ] io
  (** [read t key offset length] reads up to [length] bytes from the value
      associated with [key]. If less data is returned than requested, this
      indicates the end of the value. *)

  val size: t -> string -> [`Error of error | `Ok of int64] io
  (** Get the value size. *)

end
