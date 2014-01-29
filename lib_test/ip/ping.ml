open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: V1_LWT.CONSOLE) (N: V1_LWT.NETWORK) = struct

  module E = Ethif.Make(N)

  let start c net =
    E.connect net >>= function
    |`Error _ -> C.log_s c (red "Ethif error")
    |`Ok eth  ->
      N.listen net (
        E.input
          ~ipv4:(fun _ -> C.log_s c (blue "ipv4"))
          ~ipv6:(fun b -> C.log_s c (yellow "ipv6"))
          eth
      )

end
