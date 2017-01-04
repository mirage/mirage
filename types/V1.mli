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

open Result

(** MirageOS Signatures.

    This module defines the basic signatures that functor parameters
    should implement in MirageOS to be portable.

    {1 General conventions}

    {ul
    {- errors which application programmers are expected to handle
       (e.g. connection refused or end of file) are encoded as result types
       where [Ok x] means the operation was succesful and returns [x] and
       where [Error e] means the operation has failed with error [e].
       The error [e] uses the {!Rresult.R.msg} type for the most general
       error message, and possibly more specific ones depending on the interface. }
    {- errors which represent programming errors such as assertion failures
       or illegal arguments are encoded as exceptions. The application may
       attempt to catch exceptions and recover or simply let the exception
       propagate and crash the application. If the application crashes then
       the runtime system should output diagnostics and abort. }
    {- operations which perform I/O return values of [type +'a io] which
       allow the application to either wait for the I/O to be completed or
       leave it running asynchronously. If the I/O completes with an error
       then the operation may have completely failed, partially succeeded
       or even completely succeeded (e.g. it may only be a confirmation
       message in a network protocol which was missed): see individual API
       descriptions for details. }
    }

    {e Release %%VERSION%% } *)

module type DEVICE = Mirage_device.S

(** {1 Time and clock devices} *)

module type TIME  = Mirage_time.S
module type MCLOCK = Mirage_clock.MCLOCK
module type PCLOCK = Mirage_clock.PCLOCK

(** {1 Random}

    Operations to generate random numbers. *)
module type RANDOM = Mirage_random.S

(** {1 Connection between endpoints} *)

module type FLOW = Mirage_flow.S

(** {1 Console} *)

module type CONSOLE = Mirage_console.S

(** {1 Sector-addressible block devices} *)

module type BLOCK = Mirage_block.S

(** {1 Network stack} *)

module type NETWORK = Mirage_net.S

(** {1 Ethernet stack}

    An Ethernet stack that parses frames from a network device and
    can associate them with IP address via ARP. *)

module Ethif : sig
  type error = Mirage_device.error
end

module type ETHIF = sig

  type error = private [> Ethif.error]
  (** The type for ethernet interface errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  type buffer
  (** The type for memory buffers. *)

  type netif
  (** The type for ethernet network interfaces. *)

  type macaddr
  (** The type for unique MAC identifiers. *)

  include DEVICE

  val write: t -> buffer -> (unit, error) result io
  (** [write nf buf] outputs [buf] to netfront [nf]. *)

  val writev: t -> buffer list -> (unit, error) result io
  (** [writev nf bufs] output a list of buffers to netfront [nf] as a
      single packet. *)

  val mac: t -> macaddr
  (** [mac nf] is the MAC address of [nf]. *)

  val input:
    arpv4:(buffer -> unit io) ->
    ipv4:(buffer -> unit io) ->
    ipv6:(buffer -> unit io) ->
    t -> buffer -> unit io
  (** [listen nf fn] is a blocking operation that calls [fn buf]
      with every packet that is read from the interface.
      The function can be stopped by calling [disconnect]
      in the device layer. *)
end

(** {1 IP stack} *)

(** IP errors. *)
module Ip : sig

  type error = [
    | Mirage_device.error
    | `No_route          (** can't send a message to that destination *)
  ]

end

(** An IP stack that parses Ethernet frames into IP packets *)
module type IP = sig

  type error = private [> Ip.error]
  (** The type for IP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  type buffer
    (** The type for memory buffers. *)

  type ethif
  (** The type for ethernet devices. *)

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
  (** [allocate_frame t ~dst ~proto] returns a pair [(pkt, len)] such that
      [Cstruct.sub pkt 0 len] is the IP header (including the link layer part) of a
      packet going to [dst] for protocol [proto].  The space in [pkt] after the
      first [len] bytes can be used by the client. *)

  val write: t -> buffer -> buffer -> (unit, error) result io
  (** [write t frame buf] writes the packet [frame :: buf :: []] to
      the address [dst]. *)

  val writev: t -> buffer -> buffer list -> (unit, error) result io
  (** [writev t frame bufs] writes the packet [frame :: bufs]. *)

  val checksum: buffer -> buffer list -> int
  (** [checksum frame bufs] computes the IP checksum of [bufs]
      computing the pseudo-header from the actual header [frame].  It
      assumes that frame is of the form returned by [allocate_frame],
      i.e., that it contains the link-layer part. *)

  val pseudoheader : t -> dst:ipaddr -> proto:[< `TCP | `UDP ] -> int -> buffer
  (** [pseudoheader t dst proto len] gives a pseudoheader suitable for use in
      TCP or UDP checksum calculation based on [t]. *)

  val src: t -> dst:ipaddr -> ipaddr
  (** [src ip ~dst] is the source address to be used to send a
      packet to [dst].  In the case of IPv4, this will always return
      the same IP, which is the only one set. *)

  val set_ip: t -> ipaddr -> unit io
  (** Set the IP address associated with this interface.  For IPv4,
      currently only supports a single IPv4 address, and aliases will
      be added in a future revision. *)

  val get_ip: t -> ipaddr list
  (** Get the IP addresses associated with this interface. For IPv4, only
   *  one IP address can be set at a time, so the list will always be of
   *  length 1 (and may be the default value, 0.0.0.0). *)

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

(** {1 ARP} *)

(** Arp error. *)
module Arp : sig
  type error = [ `Timeout]
end

module type ARP = sig
  include DEVICE

  type ipaddr
  type buffer
  type macaddr
  type repr

  type error = private [> Arp.error]
  (** The type for ARP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  (** Prettyprint cache contents *)
  val to_repr : t -> repr io
  val pp : repr Fmt.t

  (** [get_ips arp] gets the bound IP address list in the [arp]
      value. *)
  val get_ips : t -> ipaddr list

  (** [set_ips arp] sets the bound IP address list, which will transmit a
      GARP packet also. *)
  val set_ips : t -> ipaddr list -> unit io

  (** [remove_ip arp ip] removes [ip] to the bound IP address list in
      the [arp] value, which will transmit a GARP packet for any remaining IPs in
      the bound IP address list after the removal. *)
  val remove_ip : t -> ipaddr -> unit io

  (** [add_ip arp ip] adds [ip] to the bound IP address list in the
      [arp] value, which will transmit a GARP packet also. *)
  val add_ip : t -> ipaddr -> unit io

  (** [query arp ip] queries the cache in [arp] for an ARP entry
      corresponding to [ip], which may result in the sender sleeping
      waiting for a response. *)
  val query : t -> ipaddr -> (macaddr, error) result io

  (** [input arp frame] will handle an ARP frame. If it is a response,
      it will update its cache, otherwise will try to satisfy the
      request. *)
  val input : t -> buffer -> unit io
end

(** {1 IPv4 stack} *)
module type IPV4 = sig
  include IP
end

(** {1 IPv6 stack} *)
module type IPV6 = sig
  include IP
end

(** {1 ICMP module} *)

(** ICMP error. *)
module Icmp : sig
  type error = [`Routing of string]
end

module type ICMP = sig
  include DEVICE

  type ipaddr
  (** The type for IP addresses. *)

  type buffer
  (** The type for buffers. *)

  type error = private [> Icmp.error]
  (** The type for ICMP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  val input : t -> src:ipaddr -> dst:ipaddr -> buffer -> unit io
  (** [input t src dst buffer] reacts to the ICMP message in
      [buffer]. *)

  val write : t -> dst:ipaddr -> buffer -> (unit, error) result io
  (** [write t dst buffer] sends the ICMP message in [buffer] to [dst]
      over IP. *)
end

module type ICMPV4 = sig
  include ICMP
end

(** {1 UDP stack} *)

(*    A UDP stack that can send and receive datagrams. *)
module type UDP = sig

  type error
  (** The type for UDP errors. *)

  val pp_error: error Fmt.t
  (** [pp] is the pretty-printer for errors. *)

  type buffer
  (** The type for memory buffers. *)

  type ip
  (** The type for IPv4/6 stacks for this stack to connect to. *)

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

  val write: ?src_port:int -> dst:ipaddr -> dst_port:int -> t -> buffer ->
    (unit, error) result io
  (** [write ~src_port ~dst ~dst_port udp data] is a thread
      that writes [data] from an optional [src_port] to a [dst]
      and [dst_port] IPv4 address pair. *)

end

(** {1 TCP stack} *)

(** TCP errors. *)
module Tcp : sig
  type error = [ `Timeout | `Refused]
  type write_error = [ error | Mirage_flow.write_error]
end

(** A TCP stack that can send and receive reliable streams using the
    TCP protocol. *)
module type TCP = sig

  type error = private [> Tcp.error]
  (** The type for TCP errors. *)

  type write_error = private [> Tcp.write_error]
  (** The type for TCP write errors. *)

  type buffer
  (** The type for memory buffers. *)

  type ip
  (** The type for IPv4 stacks for this stack to connect to. *)

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

  include DEVICE

  include FLOW with
      type 'a io  := 'a io
  and type buffer := buffer
  and type flow   := flow
  and type error  := error
  and type write_error := write_error

  type callback = flow -> unit io
  (** The type for application callback that receives a [flow] that it
      can read/write to. *)

  val dst: flow -> ipaddr * int
  (** Get the destination IPv4 address and destination port that a
      flow is currently connected to. *)

  val write_nodelay: flow -> buffer -> (unit, write_error) result io
  (** [write_nodelay flow buffer] writes the contents of [buffer]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the stack is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val writev_nodelay: flow -> buffer list -> (unit, write_error) result io
  (** [writev_nodelay flow buffers] writes the contents of [buffers]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the stack is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val create_connection: t -> ipaddr * int -> (flow, error) result io
  (** [create_connection t (addr,port)] opens a TCPv4 connection
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

  type netif
  (** The type for network interface that is used to transmit and
      receive traffic associated with this stack. *)

  type 'netif config
  (** The type for the collection of user configuration specified to
      construct a stack. *)

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

  type error
  (** The type for I/O operation errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  include DEVICE

  module UDPV4: UDP
    with type +'a io = 'a io
     and type ipaddr = ipv4addr
     and type buffer = buffer
     and type t = udpv4
     and type ip = ipv4

  module TCPV4: TCP
    with type +'a io = 'a io
     and type ipaddr = ipv4addr
     and type buffer = buffer
     and type t = tcpv4
     and type ip = ipv4

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
  (** [listen_udpv4 t ~port cb] registers the [cb] callback on the
      UDPv4 [port] and immediately return.  If [port] is invalid (not
      between 0 and 65535 inclusive), it raises [Invalid_argument].
      Multiple bindings to the same port will overwrite previous
      bindings, so callbacks will not chain if ports clash. *)

  val listen_tcpv4: t -> port:int -> TCPV4.callback -> unit
  (** [listen_tcpv4 t ~port cb] registers the [cb] callback on the
      TCPv4 [port] and immediatey return.  If [port] is invalid (not
      between 0 and 65535 inclusive), it raises [Invalid_argument].
      Multiple bindings to the same port will overwrite previous
      bindings, so callbacks will not chain if ports clash. *)

  val listen: t -> unit io
  (** [listen t] requests that the stack listen for traffic on the
      network interface associated with the stack, and demultiplex
      traffic to the appropriate callbacks. *)
end

(** {1 Buffered byte-stream} *)
module type CHANNEL = Mirage_channel.S

(** {1 Static Key/value store} *)

module type KV_RO = Mirage_kv.RO

(** {1 Filesystem devices} *)

module type FS = Mirage_fs.S
