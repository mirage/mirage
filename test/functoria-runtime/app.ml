module type K = sig end

module type I = sig
  val info : Functoria_runtime.info
end

module Make (K : K) (I : I) = struct
  let start _ _ = ()
end
