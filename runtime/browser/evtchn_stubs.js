var NR_EVENTS=128;
var ev_fds = new Array(NR_EVENTS);
var ev_callback = new Array(NR_EVENTS);

function caml_evtchn_init() {
    for (i=0; i++; i<NR_EVENTS) {
        ev_callback[i] = 0;
    };
    return ev_callback;
}
