Mirage OpenFlow Implementation
==============================

OpenFlow is a switching standard and open protocol  enabling
distributed control of the flow tables contained within Ethernet
switches in a network. Each OpenFlow switch has three parts: 

+ A **datapath**, containing a *flow table*, associating set of
  *actions* with each flow entry;
+ A **secure channel**, connecting to a controller; and
+ The **OpenFlow protocol**, used by the controller to talk to
  switches.

Following this standard model, the implementation comprises three parts: 

+ `switch.ml`, containing a skeleton OpenFlow switch;
+ `controller.ml`, containing a skeleton OpenFlow controller; and
+ `ofpacket.ml`, containing `Bitstring` parsers/writers for the
  OpenFlow protocol.

ofpacket.ml
-----------

The file begins with some utility functions, operators, types.  The
bulk of the code is organised following the v1.0.0
[protocol specification][of-1.0], as implemented by
[Open vSwitch v1.2][ovs-1.2].  Each set of messages is contained
within its own module, most of which contain a type `t` representing
the entity named by the module, plus relevant parsers to convert a
bitstring to a type (`parse_*`) and pretty printers for the type
(`string_of_*`).  At the end of the file, in the root `Ofpacket`
module scope, are definitions for interacting with the protocol as a
whole, e.g., error codes, OpenFlow message types and standard header,
root OpenFlow parser, OpenFlow packet builders. 

### Queue, Port, Switch

The `Queue` module is really a placeholder currently.  OpenFlow
defines limited quality-of-service support via a simple queueing
mechanism.  Flows are mapped to queues attached to ports, and each
queue is then configured as desired.  The specification currently
defines just a minimum rate, although specific implementations may
provide more.

The `Port` module wraps several port related elements:

+ _t_, where that is either simply the index of the port in the
  switch, or the special indexes (> 0xff00) representing the
  controller, flooding, etc.
+ _config_, a specific port's configuration (up/down, STP
  supported, etc).
+ _features_, a port's feature set (rate, fiber/copper,
  etc).
+ _state_, a port's current state (up/down, STP learning mode, etc).
+ _phy_, a port's physical details (index, address, name, etc).
+ _stats_, current statistics  of the port (packet and byte counters,
  collisions, etc).
+ _reason_ and _status_, for reporting changes to a port's
  configuration; _reason_ is one of `ADD|DEL|MOD`.
  
Finally, `Switch` wraps elements pertaining to a whole switch, that is
a collection of ports, tables (including the _group table_), and the
connection to the controller.

+ _capabilities_, the switch's capabilities in terms of supporting IP
  fragment reassembly, various statistics, etc.
+ _action_, the types of action the switch's ports support (setting
  various fields, etc).
+ _features_, the switch's id, number of buffers, tables, port list etc.
+ _config_, for masking against handling of IP fragments: no special
  handling, drop, reassemble.

### Wildcards, Match, Flow

The `Wildcards` and `Match` modules both simply wrap types
respectively representing the fields to wildcard in a flow match, and
the flow match specification itself.

The `Flow` module then contains structures representing:

+ _t_, the flow itself (its age, activity, priority, etc); and
+ _stats_, extended statistics association with a flow identified by a
  64 bit  `cookie`.

### Packet_in, Packet_out

These represent messages associated with receipt or transmission of a
packet in response to a controller initiated action.

`Packet_in` is used where a packet arrives at the switch and is
forwarded to the controller, either due to lack of matching entry, or
an explicit action.

`Packet_out` contains the structure used by the controller to indicate
to the switch that a packet it has been buffering must now have some
actions performed on it, typically culminating in it being forward out
of one or more ports.

### Flow_mod, Port_mod

These represent modification messages to existing flow and port state
in the switch.

### Stats
    
Finally, the `Stats` module contains structures representing the
different statistics messages available through OpenFlow, as well as
the request and response messages that transport them. 

[of-1.0]: http://www.openflow.org/documents/openflow-spec-v1.0.0.pdf
[of-1.1]: http://www.openflow.org/documents/openflow-spec-v1.1.0.pdf
[ovs-1.2]: http://openvswitch.org/releases/openvswitch-1.2.2.tar.gz

controller.ml
-------------

Initially modelled after [NOX][], this is a skeleton controller
that provides a simple event based wrapper around the OpenFlow
protocol.  It currently provides the minimal set of  events
corresponding to basic switch operation:

+ `DATAPATH_JOIN`, representing the connection of a datapath  to the
  controller, i.e., notification of the existence of a switch.
+ `DATAPATH_LEAVE`, representing the disconnection of a datapath from
  the controller, i.e., notification of the destruction of a switch.
+ `PACKET_IN`, representing the forwarding of a packet to the
  controller, whether through an explicit action corresponding to a
  flow match, or simply as the default when flow match is found.
  
The controller state is mutable and modelled as:

+ A list of callbacks per event, each taking the current state, the
  originating datapath, and the event;
+ Mappings from switch (`datapath_id`) to a Mirage communications
  channel (`Channel.t`); and 
+ Mappings from channel (`endhost` comprising an IPv4 address and
  port) tp datapath (`datapath_id`).
  
  
  
### Questions

What's the best way to structure the controller so that 
     
[nox]: http://noxrepo.org/


switch.ml
---------

<< Unwritten as yet >>
