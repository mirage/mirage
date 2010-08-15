external xenstore_port : unit -> int = "stub_xenstore_evtchn_port"
external alloc_unbound_port : int -> int = "stub_evtchn_alloc_unbound"
external unmask : int -> unit = "stub_evtchn_unmask"
external notify : int -> unit = "stub_evtchn_notify"
