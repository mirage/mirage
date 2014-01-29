open Lwt

module Make (X: V1_LWT.KV_RO) (Y: V1_LWT.KV_RO) = struct

  type 'a io = 'a Lwt.t

  type t = X.t * Y.t

  type id = X.id * Y.id

  type page_aligned_buffer = X.page_aligned_buffer

  type error = Unknown_key of string

  let id (x, y) =
    (X.id x, Y.id y)

  (* because of the non-composibale [error] type *)
  let wrap_x fn x =
    fn x >>= function
    | `Error (X.Unknown_key e) -> return (`Error (Unknown_key e))
    | `Ok _ as x -> return x

  let wrap_y fn y =
    fn y >>= function
    | `Error (Y.Unknown_key e) -> return (`Error (Unknown_key e))
    | `Ok _ as y -> return y

  let connect (x, y) =
    wrap_x X.connect x >>= function
    | `Error _ as e -> return e
    | `Ok x ->
    wrap_y Y.connect y >>= function
    | `Error _ as e -> return e
    | `Ok y -> return (`Ok (x, y))

  let disconnect (x, y) =
    X.disconnect x >>= fun () ->
    Y.disconnect y

  let read (x, y) str off len =
    let rx = wrap_x (fun x -> X.read x str off len) x in
    let ry = wrap_y (fun y -> Y.read y str off len) y in
    Lwt.pick [rx; ry]

  let size (x, y) str =
    let sx = wrap_x (fun x -> X.size x str) x in
    let sy = wrap_y (fun y -> Y.size y str) y in
    Lwt.pick [sx; sy]

end
