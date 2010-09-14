var NR_EVENTS=128;
var ev_fds = new Array(NR_EVENTS);
var ev_callback = new Array(NR_EVENTS);

function caml_evtchn_init() {
    if (window.console) console.debug("ev_callback init");
    for (i=0; i++; i<NR_EVENTS) {
        ev_callback[i] = 0;
    };
    return ev_callback;
}

function evtchn_block_domain(tm) {
	  if (window.console) console.debug("block(%d)", tm);
    if (tm >= 0)
        setTimeout("ocamljs$caml_named_value('evtchn_run')(0)", tm * 1000);
}

