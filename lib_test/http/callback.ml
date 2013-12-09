module type TCPIP = module type of Net.Manager

module type HTTP = module type of Cohttp_lwt.SERVER

module Main (C: CONSOLE) (T: TCPIP) (H: HTTP) = struct

  let start c ip http =
    failwith "TODO"

end
