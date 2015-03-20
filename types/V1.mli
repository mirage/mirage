(*
 * Copyright (c) 2011-2015 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** MirageOS Signatures.

    This module defines the basic signatures that functor parameters
    should implement in MirageOS to be portable. *)

type ('a, 'b) result = ('a, 'b) Rresult.result = Ok of 'a | Error of 'b
(** {b FIXME} Use {!Rresult} *)

(** {1 Abtract devices}

    Defines the functions to define what is a device state and how to
    disconnect such a device. *)
module type DEVICE = sig

  type +'a io
  (** The type for potentially blocking I/O operation *)

  type t
  (** The type representing the internal state of the device *)

  val pp: Format.formatter -> t -> unit
  (** Pretty-print device states. *)

  val disconnect: t -> unit io
  (** Disconnect from the device.  While this might take some time to
      complete, it can never result in an error. *)
end

(** {1 Time operations for cooperative threads} *)
module type TIME = sig

  type +'a io
  (** The type for potentially blocking I/O operation *)

  val sleep: float -> unit io
  (** [sleep nsec] Block the current thread for. {b FIXME:} remove float. *)
end

(** {1 Random}

    Operations to generate entropy. This is currently a passthrough
    to the OCaml Random generator, and will be deprecated in V2 and
    turned into a proper DEVICE with blocking modes. *)
module type RANDOM = sig

  val self_init: unit -> unit
  (** Initialize the generator with a random seed chosen in a
      system-dependent way. *)

  val int: int -> int
  (** [int bound] returns a random integer between 0 (inclusive) and
      [bound] (exclusive). [bound] must be greater than 0 and less
      than 2{^30}. *)

  val int32: int32 -> int32
  (** [int32 bound] returns a random integer between 0 (inclusive) and
      [bound] (exclusive). [bound] must be greater than 0. *)
end

(** {1 Native entropy provider} **)
module type ENTROPY = sig

  include DEVICE

  type buffer
  (** The type for memory buffers. *)

  type handler = source:int -> buffer -> unit
  (** A [handler] is called whenever the system has extra entropy to
      announce.  No guarantees are made about the entropy itself,
      other than it being environmentally derived. In particular, the
      amount of entropy in the buffer can be far lower than the size
      of the [buffer].

      [source] is a small integer, describing the provider but with no
      other meaning.

      [handler] is expected to return quickly.  *)

  val handler: t -> handler -> unit io
  (** [handler h] registers the single global [handler] that will
      receive entropy. There might be additional, provider-specific
      blocking semantics.  *)

end

(** {1 Clock operations}

    Currently read-only to retrieve the time in various formats. *)
module type CLOCK = sig

  type tm =
    { tm_sec: int;               (** Seconds 0..60 *)
      tm_min: int;               (** Minutes 0..59 *)
      tm_hour: int;              (** Hours 0..23 *)
      tm_mday: int;              (** Day of month 1..31 *)
      tm_mon: int;               (** Month of year 0..11 *)
      tm_year: int;              (** Year - 1900 *)
      tm_wday: int;              (** Day of week (Sunday is 0) *)
      tm_yday: int;              (** Day of year 0..365 *)
      tm_isdst: bool;            (** Daylight time savings in effect *)
    }
  (** The type for representing wallclock time and calendar date. *)

  val time: unit -> float
  (** Return the current time since 00:00:00 GMT, Jan. 1, 1970, in
      seconds. *)

  val gmtime: float -> tm
  (** Convert a time in seconds, as returned by {!time}, into a date
      and a time. Assumes UTC (Coordinated Universal Time), also known
      as GMT. *)
end

(** {1 Connection between endpoints} *)
module type FLOW = sig

  type +'a io
  (** The type for potentially blocking I/O operation *)

  type buffer
  (** The type for memory buffer. *)

  type t
  (** The type for flows. A flow represents the state of a single
      stream that is connected to an endpoint. *)

  type error = private [> `Eof]
  (** The type for flow errors. *)

  val pp_error: Format.formatter -> error -> unit
  (** Convert an error to a human-readable message, suitable for
      logging. *)

  val read: t -> (buffer, error) result  io
  (** [read flow] will block until it either successfully reads a
      segment of data from the current flow, receives an [`Eof]
      signifying that the connection is now closed. *)

  val write: t -> buffer -> (unit, error) result io
  (** [write flow buffer] will block until [buffer] has been added to
      the send queue. There is no indication when the buffer has
      actually been read and, therefore, it must not be reused.  The
      contents may be transmitted in separate packets, depending on
      the underlying transport. *)

  val writev: t -> buffer list -> (unit, error) result io
  (** [writev flow buffers] will block until the buffers have all been
      added to the send queue. There is no indication when the buffers
      have actually been read and, therefore, they must not be
      reused. *)

  val close: t -> unit io
  (** [close flow] will flush all pending writes and signal the end of
      the flow to the remote endpoint.  When the result [unit io]
      becomes determined, all further calls to [read flow] will result
      in a [`Eof]. *)

end

(** {1 Console input/output} *)
module type CONSOLE = sig

  type error = private [> `Eof | `Invalid_console of string ]
  (** The type for representing possible errors when attaching a
      console. *)

  include DEVICE

  include FLOW with
      type error  := error
  and type 'a io  := 'a io
  and type t      := t

  val log: t -> string -> unit
  (** [log str] writes as much characters of [str] that can be written
      in one write operation to the console [t], then writes "\r\n" to
      it. *)

  val log_s: t -> string -> unit io
  (** [log_s str] is a thread that writes [str ^ "\r\n"] in the
      console [t]. *)

end

(** {1 Sector-addressible block devices}

    Operations on sector-addressible block devices, usually used
    for persistent storage *)
module type BLOCK = sig

  type buffer
  (** The type for page-aligned memory buffers. *)

  type error = private [>
    | `Unimplemented     (** operation not yet implemented in the code *)
    | `Is_read_only      (** you cannot write to a read/only instance *)
    | `Disconnected      (** the device has been previously disconnected *)
  ]
  (** The type for IO operation errors. *)


  include DEVICE

  type info = {
    read_write: bool;    (** True if we can write, false if read/only *)
    sector_size: int;    (** Octets per sector *)
    size_sectors: int64; (** Total sectors per device *)
  }
  (** Characteristics of the block device. Note some devices may be
      able to make themselves bigger over time. *)

  val get_info: t -> info io
  (** Query the characteristics of a specific block device *)

  val read: t -> int64 -> buffer list -> (unit, error) result io
  (** [read device sector_start buffers] returns a blocking IO
      operation which attempts to fill [buffers] with data starting at
      [sector_start].  Each of [buffers] must be a whole number of
      sectors in length. The list of buffers can be of any length. *)

  val write: t -> int64 -> buffer list -> (unit, error) result io
  (** [write device sector_start buffers] returns a blocking IO
      operation which attempts to write the data contained within
      [buffers] to [t] starting at [sector_start]. When the IO
      operation completes then all writes have been persisted.

      Once submitted, it is not possible to cancel a request and there
      is no timeout.

      The operation may fail with:

      {ul

      {- [`Unimplemented]: the operation has not been implemented, no
      data has been written.}
      {- [`Is_read_only]: the device is read-only, no data has been
      written.}
      {- [`Disconnected]: the device has been disconnected at
        application request, an unknown amount of data has been
        written.}
      }

      Each of [buffers] must be a whole number of sectors in
      length. The list of buffers can be of any length.

      The data will not be copied, so the supplied buffers must not be
      re-used until the IO operation completes. *)

end

(** {1 Network stack}

    A network interface that serves Ethernet frames. *)
module type NETWORK = sig

  type buffer
  (** The type for memory buffers. *)

  type macaddr
  (** The type for unique MAC identifiers for the device. *)

  include DEVICE

  val write: t -> buffer -> unit io
  (** [write nf buf] outputs [buf] to netfront [nf]. *)

  val writev: t -> buffer list -> unit io
  (** [writev nf bufs] output a list of buffers to netfront [nf] as a
      single packet. *)

  val listen: t -> (buffer -> unit io) -> unit io
  (** [listen nf fn] is a blocking operation that calls [fn buf] with
      every packet that is read from the interface.  It returns as
      soon as it has initialised, and the function can be stopped by
      calling [disconnect] in the device layer. *)

  val mac: t -> macaddr
  (** [mac nf] is the MAC address of [nf]. *)

  type stats = {
    mutable rx_bytes: int64;
    mutable rx_pkts: int32;
    mutable tx_bytes: int64;
    mutable tx_pkts: int32;
  }
  (** The type for frame statistics to track the usage of the
      device. *)

  val get_stats_counters: t -> stats
  (** Obtain the most recent snapshot of the device statistics. *)

  val reset_stats_counters: t -> unit
  (** Reset the statistics associated with this device to their
      defaults. *)
end

(** {1 Ethernet stack}

    An Ethernet stack that parses frames from a network device and
    can associate them with IP address via ARP. *)
module type ETHIF = sig

  type buffer
  (** The type for memory buffers. *)

  type macaddr
  (** The type for unique MAC identifiers. *)

  include DEVICE

  val write: t -> buffer -> unit io
  (** [write nf buf] outputs [buf] to netfront [nf]. *)

  val writev: t -> buffer list -> unit io
  (** [writev nf bufs] output a list of buffers to netfront [nf] as a
      single packet. *)

  val mac: t -> macaddr
  (** [mac nf] is the MAC address of [nf]. *)

  val input: arpv4:(buffer -> unit io) -> ipv4:(buffer -> unit io) -> ipv6:(buffer -> unit io) -> t -> buffer -> unit io
  (** {b FIXME} [listen nf fn] is a blocking operation that calls [fn
      buf] with every packet that is read from the interface.  It
      returns as soon as it has initialised, and the function can be
      stopped by calling [disconnect] in the device layer. *)
end

(** {1 IP stack}

    An IP stack that parses Ethernet frames into IP packets *)
module type IP = sig

  type buffer
    (** The type for memory buffers. *)

  type ipaddr
  (** The type for IP addresses. *)

  type prefix
  (** The type for IP prefixes. *)

  include DEVICE

  type callback = src:ipaddr -> dst:ipaddr -> buffer -> unit io
  (** An input continuation used by the parsing functions to pass on
      an input packet down the stack.

      [callback ~src ~dst buf] will be called with [src] and [dst]
      containing the source and destination IP address respectively,
      and [buf] will be a buffer pointing at the start of the IP
      payload. *)

  val input:
    t ->
    tcp:callback -> udp:callback -> default:(proto:int -> callback) ->
    buffer -> unit io
  (** [input ~tcp ~udp ~default ip buf] demultiplexes an incoming
      [buffer] that contains an IP frame. It examines the protocol
      header and passes the result onto either the [tcp] or [udp]
      function, or the [default] function for unknown IP protocols. *)

  val allocate_frame: t -> dst:ipaddr -> proto:[`ICMP | `TCP | `UDP] -> buffer * int
  (** [allocate_frame t ~dst ~proto] retrurns a pair [(pkt, len)] such that
      [Cstruct.sub pkt 0 len] is the IP header (including the link layer part) of a
      packet going to [dst] for protocol [proto].  The space in [pkt] after the
      first [len] bytes can be used by the client. *)

  val write: t -> buffer -> buffer -> unit io
  (** [write t frame buf] writes the packet [frame :: buf :: []] to
      the address [dst]. *)

  val writev: t -> buffer -> buffer list -> unit io
  (** [writev t frame bufs] writes the packet [frame :: bufs]. *)

  val checksum: buffer -> buffer list -> int
  (** [checksum frame bufs] computes the IP checksum of [bufs]
      computing the pseudo-header from the actual header [frame].  It
      assumes that frame is of the form returned by [allocate_frame],
      i.e., that it contains the link-layer part. *)

  val get_source: t -> dst:ipaddr -> ipaddr
  (** [get_source ip ~dst] is the source address to be used to send a
      packet to [dst]. *)

  val set_ip: t -> ipaddr -> unit io
  (** Set the IP address associated with this interface.  For IPv4,
      currently only supports a single IPv4 address, and aliases will
      be added in a future revision. *)

  val get_ip: t -> ipaddr list
  (** Get the IP addresses associated with this interface. *)

  val set_ip_netmask: t -> prefix -> unit io
  (** Set an IP netmask associated with this interface.  For IPv4,
      currently only supports a single IPv4 netmask, and aliases will
      be added in a future revision. *)

  val get_ip_netmasks: t -> prefix list
  (** Get the IP netmasks associated with this interface. *)

  val set_ip_gateways: t -> ipaddr list -> unit io
  (** Set an IP gateways associated with this interface. *)

  val get_ip_gateways: t -> ipaddr list
  (** Get the IP gateways associated with this interface. *)

  type uipaddr
  (** The type for universal IP addresses. It supports all the
      possible versions. *)

  val to_uipaddr: ipaddr -> uipaddr
  (** Convert an IP address with a specific version (eg. V4) into a
      universal IP address. *)

  val of_uipaddr: uipaddr -> ipaddr option
  (** Project a universal IP address into the version supported by the
      current implementation. Return [None] if there is a version
      mismatch. *)

end

(** {1 IPv4 stack} *)
module type IPV4 = sig
  include IP

  val input_arpv4: t -> buffer -> unit io
  (** {b FIXME} *)

end

(** {1 IPv6 stack} *)
module type IPV6 = sig
  include IP
end

(** {1 UDP stack}

    A UDP stack that can send and receive datagrams. *)
module type UDP = sig

  type buffer
  (** The type for memory buffers. *)

  type ipaddr
  (** The type for an IP address representations. *)

  type ipinput
  (** The type for input function continuation to pass onto the
      underlying {!IP} stack. This will normally be a NOOP for a
      conventional kernel, but a direct implementation will parse the
      buffer. *)

  include DEVICE

  type callback = src:ipaddr -> dst:ipaddr -> src_port:int -> buffer -> unit io
  (** The type for callback functions that adds the UDP metadata for
      [src] and [dst] IP addresses, the [src_port] of the connection
      and the [buffer] payload of the datagram. *)

  val input: listeners:(dst_port:int -> callback option) -> t -> ipinput
  (** [input listeners t] demultiplexes incoming datagrams based on
      their destination port.  The [listeners] callback will either
      return a concrete handler or a [None], which results in the
      datagram being dropped. *)

  val write: ?source_port:int -> dest_ip:ipaddr -> dest_port:int -> t -> buffer -> unit io
  (** [write ~source_port ~dest_ip ~dest_port udp data] is a thread
      that writes [data] from an optional [source_port] to a [dest_ip]
      and [dest_port] IPv4 address pair. *)
end

(** {1 TCP stack}

    A TCP stack that can send and receive reliable streams using the
    TCP protocol. *)
module type TCP = sig

  type buffer
  (** The type for memory buffers. *)

  type ipaddr
  (** The type for IP address representations. *)

  type ipinput
  (** The type for input function continuation to pass onto the
      underlying {!IP} stack. This will normally be a NOOP for a
      conventional kernel, but a direct implementation will parse the
      buffer. *)

  type flow
  (** A flow represents the state of a single TCPv4 stream that is connected
      to an endpoint. *)

  type error = private [>
    | `Eof
    | `Timeout  (** connection attempt did not get a valid response. *)
    | `Refused  (** connection attempt was actively refused via an RST. *)
  ]
  (** The type for IO operation errors. *)

  include DEVICE with type error := error

  include FLOW with
      type error  := error
  and type 'a io  := 'a io
  and type buffer := buffer
  and type t      := flow

  type callback = flow -> unit io
  (** The type for application callback that receives a [flow] that it
      can read/write to. *)

  val get_dest: flow -> ipaddr * int
  (** Get the destination IPv4 address and destination port that a
      flow is currently connected to. *)

  val write_nodelay: flow -> buffer -> unit io
  (** [write_nodelay flow] will block until the contents of [buffer
      list] are all successfully transmitted to the remote
      endpoint. Buffering within the stack is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val writev_nodelay: flow -> buffer list -> unit io
  (** [writev_nodelay flow] will block until the contents of [buffer
      list] are all successfully transmitted to the remote
      endpoint. Buffering within the stack is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val create_connection: t -> ipaddr * int -> (flow, error) result io
  (** [create_connection t (addr,port)] will open a TCPv4 connection
      to the specified endpoint. *)

  val input: t -> listeners:(int -> callback option) -> ipinput
  (** [input t listeners] defines a mapping of threads that are
      willing to accept new flows on a given port.  If the [callback]
      returns [None], the input function will return an RST to refuse
      connections on a port. *)
end

(** {1 TCP/IPv4 stack}

    A complete TCP/IPv4 stack that can be used by applications to
    receive and transmit network traffic. *)
module type STACKV4 = sig

  type ipv4addr
  (** The type for IPv4 addresses. *)

  type buffer
  (** The type for memory buffers. *)

  type udpv4
  (** The type for UDPv4 stacks. *)

  type tcpv4
  (** The type for TCPv4 stacks. *)

  type ipv4
  (** The type for IPv4 stacks. *)

  include DEVICE

  module UDPV4: UDP
    with type +'a io = 'a io
     and type ipaddr = ipv4addr
     and type buffer = buffer
     and type t = udpv4

  module TCPV4: TCP
    with type +'a io = 'a io
     and type ipaddr = ipv4addr
     and type buffer = buffer
     and type t = tcpv4

  module IPV4: IPV4
    with type +'a io = 'a io
     and type ipaddr = ipv4addr
     and type buffer = buffer
     and type t = ipv4

  val udpv4: t -> udpv4
  (** [udpv4 t] obtains a descriptor for use with the [UDPV4] module,
      usually to transmit traffic. *)

  val tcpv4: t -> tcpv4
  (** [tcpv4 t] obtains a descriptor for use with the [TCPV4] module,
      usually to initiate outgoing connections. *)

  val ipv4: t -> ipv4
  (** [ipv4 t] obtains a descriptor for use with the [IPV4] module,
      which can handle raw IPv4 frames, or manipulate IP address
      configuration on the stack interface. *)

  val listen_udpv4: t -> port:int -> UDPV4.callback -> unit
  (** [listen_udpv4 t ~port cb] will register the [cb] callback on the
      UDPv4 [port] and immediately return.  Multiple bindings to the
      same port will overwrite previous bindings, so callbacks will
      not chain if ports clash. *)

  val listen_tcpv4: t -> port:int -> TCPV4.callback -> unit
  (** [listen_tcpv4 t ~port cb] will register the [cb] callback on the
      TCPv4 [port] and immediately return.  Multiple bindings to the
      same port will overwrite previous bindings, so callbacks will
      not chain if ports clash. *)

  val listen: t -> unit io
  (** [listen t] will cause the stack to listen for traffic on the
      network interface associated with the stack, and demultiplex
      traffic to the appropriate callbacks. *)
end

(** {1 Buffered byte-stream}

    Type of a buffered byte-stream that is attached to an unbuffered
    flow (e.g. a TCPv4 connection). *)
module type CHANNEL = sig

  type buffer
    (** The type for memory buffers. *)

  type flow
  (** The type for unbuffered network flow. *)

  type t
  (** The type for the state associated with channels, such as the
      inflight buffers. *)

  type +'a io
  (** The type for potentially blocking I/O operation *)

  type 'a io_stream
  (** The type for potentially blocking stream of IO requests. *)

  val create: flow -> t
  (** [create flow] will allocate send and receive buffers and
      associated them with the given unbuffered [flow]. *)

  val to_flow: t -> flow
  (** [to_flow t] will return the flow that backs this channel. *)

  val read_char: t -> char io
  (** Read a single character from the channel, blocking if there is
      no immediately available input data. *)

  val read_until: t -> char -> (bool * buffer) io
  (** [read_until t ch] will read from the channel until the given
      [ch] character is found.  It returns a tuple indicating whether
      the character was found at all ([false] indicates that an EOF
      condition occurred before the character was encountered), and
      the [buffer] pointing to the position immediately after the
      character (or the complete scanned buffer if the character was
      never encountered). *)

  val read_some: ?len:int -> t -> buffer io
  (** [read_some ?len t] will read up to [len] characters from the
      input channel and at most a full [buffer]. If [len] is not
      specified, it will read all available data and return that
      buffer. *)

  val read_stream: ?len:int -> t -> buffer io_stream
  (** [read_stream ?len t] will return up to [len] characters as a
      stream of buffers. This call will probably be removed in a
      future revision of the API in favour of {!read_some}. *)

  val read_line: t -> buffer list io
  (** [read_line t] will read a line of input, which is terminated
      either by a CRLF sequence, or the end of the channel (which
      counts as a line).  @return Returns a list of views that
      terminates at EOF. *)

  val write_char: t -> char -> unit
  (** [write_char t ch] writes a single character to the output
      channel. *)

  val write_string: t -> string -> int -> int -> unit
  (** [write_string t buf off len] writes [len] bytes from a string
      [buf], starting from from offset [off]. *)

  val write_buffer: t -> buffer -> unit
  (** [write_buffer t buf] will copy the buffer to the channel's
      output buffer.  The buffer should not be modified after being
      written, and it will be recycled into the buffer allocation pool
      at some future point. *)

  val write_line: t -> string -> unit
  (** [write_line t buf] will write the string [buf] to the output
      channel and append a newline character afterwards. *)

  val flush: t -> unit io
  (** [flush t] will flush the output buffer and block if necessary
      until it is all written out to the flow. *)

  val close: t -> unit io
  (** [close t] will call {!flush} and then close the underlying
      flow. *)

end

(** {1 Filesystem} *)
module type FS = sig

  type block_device_error
  (** The type for errors from the block layer *)

  type error = private [>
    | `Not_a_directory of string             (** Cannot create a directory entry in a file *)
    | `Is_a_directory of string              (** Cannot read or write the contents of a directory *)
    | `Directory_not_empty of string         (** Cannot remove a non-empty directory *)
    | `No_directory_entry of string * string (** Cannot find a directory entry *)
    | `File_already_exists of string         (** Cannot create a file with a duplicate name *)
    | `No_space                              (** No space left on the block device *)
    | `Format_not_recognised of string       (** The block device appears to not be formatted *)
    | `Block_device of block_device_error
  ]
  (** The type for filesystem errors. *)

  include DEVICE

  type buffer
  (** The type for memory buffers. *)

  val read: t -> string -> int -> int -> (buffer, error) result io
  (** [read t key offset length] reads up to [length] bytes from the
      value associated with [key]. If less data is returned than
      requested, this indicates the end of the value. *)

  val size: t -> string -> (int64, error) result io
  (** Get the value size. *)

  type stat = {
    filename: string; (** Filename within the enclosing directory *)
    read_only: bool;  (** True means the contents are read-only *)
    directory: bool;  (** True means the entity is a directory; false means a file *)
    size: int64;      (** Size of the entity in bytes *)
  }
  (** The type for Per-file/directory statistics. *)

  val format: t -> int64 -> (unit, error) result io
  (** [format t size] erases the contents of [t] and creates an empty
      filesystem of size [size] bytes. *)

  val create: t -> string -> (unit, error) result io
  (** [create t path] creates an empty file at [path]. *)

  val mkdir: t -> string -> (unit, error) result io
  (** [mkdir t path] creates an empty directory at [path]. *)

  val destroy: t -> string -> (unit, error) result io
  (** [destroy t path] removes a [path] (which may be a file or an
      empty directory) on filesystem [t]. *)

  val stat: t -> string -> (stat, error) result io
  (** [stat t path] returns information about file or directory at
      [path]. *)

  val listdir: t -> string -> (string list, error) result io
  (** [listdir t path] returns the names of files and subdirectories
      within the directory [path]. *)

  val write: t -> string -> int -> buffer -> (unit, error) result io
  (** [write t path offset data] writes [data] at [offset] in file
      [path] on filesystem [t]. *)

end

(** {1 Static Key/value store} *)
module type KV_RO = sig

  type error = private [> `Unknown_key of string]

  include DEVICE

  type buffer
  (** The type for memory buffers.*)

  val read: t -> string -> int -> int -> (buffer, error) result io
  (** [read t key offset length] reads up to [length] bytes from the
      value associated with [key]. If less data is returned than
      requested, this indicates the end of the value. *)

  val size: t -> string -> (int64, error) result io
  (** Get the value size. *)

end
