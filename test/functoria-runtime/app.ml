module type K = sig
  val runtime_keys : (unit Cmdliner.Term.t * string) list
end

module Make (K : K) = struct
  let start _ = ()
end
