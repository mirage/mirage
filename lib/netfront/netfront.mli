type netfront
val create: Xs.xsh -> (int * int) -> netfront Lwt.t
val enumerate: Xs.xsh -> (int * int) list Lwt.t
