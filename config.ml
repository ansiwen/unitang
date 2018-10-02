open Mirage

let stack = generic_stackv4 default_network

(* set ~tls to false to get a plain-http server *)
let http_srv = http_server @@ conduit_direct ~tls:false stack

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
    package "yojson";
    package ~min:"0.6.0" "webmachine";
  ] in
  let keys = [ http_port; d_key; adv_jws ] in
  foreign
    ~packages ~keys
    "Tang.Main" (pclock @-> http @-> job)

let () =
  register "unitang" [main $ default_posix_clock $ http_srv]
