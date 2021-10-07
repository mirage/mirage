module Make (_ : sig end) = struct
  let start () =
    Fmt.pr "Success: vote=%s hello=%s\n%!" Key_gen.(vote ()) Key_gen.(hello ())
end
