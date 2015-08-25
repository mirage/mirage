(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

open Cmdliner

module Key = struct

  type 'a t = {
    doc : Arg.info ;
    converter : 'a Arg.converter ;
    default : 'a ;
    mutable value : 'a option ;
  }

  let create ~doc ~default converter =
    { doc ; default ; converter ; value = None }

  let get k = match k.value with
    | None -> k.default
    | Some v -> v

  let term ({ doc; converter; default } as t) =
    let set w = t.value <- Some w in
    Term.(pure set $ Arg.(value & opt converter default doc))

end

let with_argv keys s argv =
  let open Cmdliner in
  let gather k rest = Term.(pure (fun () () -> ()) $ k $ rest) in
  let t = List.fold_right gather keys (Term.pure ()) in
  match Term.(eval ~argv (t, info s)) with
  | `Ok _ -> Lwt.return (`Ok ())
  | _ -> Lwt.return (`Error "cmdliner")

(* Put back the dashes. Slightly hacky. *)
let with_kv keys s kv =
  let argv = Array.make (1 + List.length kv) "" in
  let f i (k,v) =
    let dash = if String.length k = 1 then "-" else "--" in
    argv.(i + 1) <- Printf.sprintf "%s%s=%s" dash k v
  in List.iteri f kv;
  with_argv keys s argv
