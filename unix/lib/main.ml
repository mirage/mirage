open Lwt

let exit_hooks = Lwt_sequence.create ()
let enter_hooks = Lwt_sequence.create ()

let rec call_hooks hooks  =
  match Lwt_sequence.take_opt_l hooks with
    | None ->
        return ()
    | Some f ->
        (* Run the hooks in parallel *)
        let _ =
          try_lwt
            f ()
          with exn ->
            Printf.printf "enter_t: exn %s\n%!" (Printexc.to_string exn);
            return ()
        in
        call_hooks hooks

open Printf

(* Main runloop, which registers a callback so it can be invoked
   when timeouts expire. Thus, the program may only call this function
   once and once only. *)
let run t =
  let t = call_hooks enter_hooks <&> t in
  Lwt_unix.run t

let () = at_exit (fun () -> run (call_hooks exit_hooks))
let at_exit f = ignore (Lwt_sequence.add_l f exit_hooks)
let at_enter f = ignore (Lwt_sequence.add_l f enter_hooks)
