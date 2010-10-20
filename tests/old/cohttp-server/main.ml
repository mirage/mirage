open Cohttp
open Lwt

module Site = struct
    open Http_daemon
    let heading_slash str = str <> ""

    let callback _ req =
      let path = Http_request.path req in
      if not (heading_slash path) then
        respond_error ~status:(`Code 400) ()
      else
        respond ~body:"hello world" ()

   let exn_handler exn =
     return ()

   let conn_closed conn_id =
     ()

   let spec = {
     address = "0.0.0.0";
     auth = `None;
     callback = callback;
     conn_closed = conn_closed;
     port = 8080;
     exn_handler = exn_handler;
     timeout = Some 300.;
   }
  end

let _ =
  let spec = Site.spec in
  OS.Main.run ( 
    Log.logmod "Server" "listening to HTTP on port %d" spec.Http_daemon.port;
    Http_daemon.main spec
  )
