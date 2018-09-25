open Big_int_Z

module ZI : (Field.t with type element = int) = Z_int
module ZB : (Field.t with type element = Z.t) = Z_big_int

module F1009 = F_big_int.Make (struct type element = Z.t let p = big_int_of_int 1009 end)

module ECSpec1009 = struct
  type element = Z.t

  let a = big_int_of_int 71
  let b = big_int_of_int 602
end

module E1009 = Ec.Make (F1009) (ECSpec1009)

module F22BIT = F_big_int.Make (struct type element = Z.t let p = big_int_of_int 4063417 end)

module ECSpec22BIT = struct
  type element = Z.t

  let a = big_int_of_int 83527
  let b = big_int_of_int 42987
end

module E22BIT = Ec.Make (F22BIT) (ECSpec22BIT)

module P192BIT = struct
  type element = Z.t

  (* 2^192 - 2^64 - 1 *)
  let p = big_int_of_string "6277101735386680763835789423207666416083908700390324961279"
end

module F192BIT = F_big_int.Make (P192BIT)

module ECSpec192BIT = struct
  type element = Z.t

  let a = big_int_of_string "6277101735386680763835789423207666416083908700390324961276"
  let b = big_int_of_string "2455155546008943817740293915197451784769108058161191238065"

  let order = big_int_of_string "6277101735386680763835789423176059013767194773182842284081"
end

module E192BIT = Ec.Make (F192BIT) (ECSpec192BIT)

module P224BIT = struct
  type element = Z.t

  let p = big_int_of_string "26959946667150639794667015087019630673557916260026308143510066298881"
end

module F224BIT = F_big_int.Make (P224BIT)

module ECSpec224BIT = struct
  type element = Z.t

  let a = big_int_of_string "26959946667150639794667015087019630673557916260026308143510066298878"
  let b = F224BIT.of_hex "b4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4"

  let order = big_int_of_string "26959946667150639794667015087019625940457807714424391721682722368061"
end

module E224BIT = Ec.Make (F224BIT) (ECSpec224BIT)

module P521BIT = struct
  type element = Z.t

  let p = big_int_of_string "6864797660130609714981900799081393217269435300143305409394463459185543183397656052122559640661454554977296311391480858037121987999716643812574028291115057151"
end

module F521BIT = F_big_int.Make (P521BIT)

module ECSpec521BIT = struct
  type element = Z.t

  let a = big_int_of_string "6864797660130609714981900799081393217269435300143305409394463459185543183397656052122559640661454554977296311391480858037121987999716643812574028291115057148"
  let b = F521BIT.of_hex "051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00"

  let order = big_int_of_string "6864797660130609714981900799081393217269435300143305409394463459185543183397655394245057746333217197532963996371363321113864768612440380340372808892707005449"
end

module E521BIT = Ec.Make (F521BIT) (ECSpec521BIT)
