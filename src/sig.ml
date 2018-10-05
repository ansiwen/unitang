module type CURVE = sig
  val multiply : Z.t -> Z.t * Z.t -> Z.t * Z.t
end
