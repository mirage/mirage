open Lwt

let (>>>) x f =
  x >>= function
  | `Error _ -> failwith "error"
  | `Ok x    -> f x

module Main (C: V1_LWT.CONSOLE) (FS: V1_LWT.KV_RO) (Server: Cohttp_lwt.Server) = struct

  let respond_string body =
    Server.respond_string ~status:`OK ~body ()

  let start c fs http =

    let callback conn_id ?body req =
      let path = Uri.path (Server.Request.uri req) in
      C.log_s c (Printf.sprintf "Got a request for %s\n" path) >>= fun () ->
      FS.size fs path                    >>> fun s ->
      FS.read fs path 0 (Int64.to_int s) >>> fun v ->
      let r = Cstruct.copyv v in
      respond_string r
    in

    let spec = {
      Server.callback;
      conn_closed = fun _ () -> ();
    } in
    http spec

end
