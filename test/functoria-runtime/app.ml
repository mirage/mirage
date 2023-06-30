module type K = sig end

module Make (K : K) = struct
  let start _ = ()
end
