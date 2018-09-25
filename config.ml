open Mirage

let stack = generic_stackv4 default_network

(* set ~tls to false to get a plain-http server *)
let con = conduit_direct ~tls:true stack

let http_port =
  let doc = Key.Arg.info ~doc:"Listening HTTP port." ["port"] in
  Key.abstract Key.(create "http_port" Arg.(opt int 8080 doc))

let d_key =
  let doc = Key.Arg.info ~doc:"derive key base64 encoded." ["dkey"] in
  Key.abstract Key.(create "d_key"
    Arg.(required ~stage:`Both string doc))

let adv_jws =
  let doc = Key.Arg.info ~doc:"The advertised jws containing the public key of \
    the derive key." ["adv"] in
  Key.abstract Key.(create "adv_jws"
    Arg.(required ~stage:`Both string doc))

let main =
  let packages = [
    package "cohttp-mirage";
    package "uri";
    package "magic-mime";
    package "yojson";
    package ~min:"0.6.0" "webmachine";
    package "ppx_sexp_conv";
  ] in
  let keys = [ http_port; d_key; adv_jws ] in
  foreign
    ~packages ~keys
    "Tang.Main" (pclock @-> conduit @-> job)

let () =
  register "unitang" [main $ default_posix_clock $ con]
