(*
 * Copyright (c) Citrix Systems Inc
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

type reason =
  | Poweroff
  | Reboot
  | Suspend
  | Crash

external shutdown: reason -> unit = "stub_sched_shutdown"

external _suspend: unit -> int = "stub_hypervisor_suspend"

let suspend () =
  lwt () = Xs.pre_suspend () in
  Gnttab.pre_suspend ();
  let result = _suspend () in
  Gnttab.post_suspend ();
  Activations.post_suspend ();
  lwt () = Console.log_s "Before Xs.post_suspend" in
  lwt () = Xs.post_suspend () in
  lwt () = Console.log_s "After Xs.post_suspend" in
  lwt () = Blkif.post_suspend () in
  Lwt.return result
  
