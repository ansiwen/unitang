open Lwt.Infix

(** Common signature for http and https. *)
module type HTTP_SERVER = Cohttp_lwt.S.Server

(* Logging *)
let http_src = Logs.Src.create "http" ~doc:"HTTP server"
module Http_log = (val Logs.src_log http_src : Logs.LOG)

module Dispatch
    (Serv: HTTP_SERVER)
    (Clock: Webmachine.CLOCK)
= struct

  module API = Api.Dispatch(Serv)(Clock)

  let serve =
    let callback (_, cid) request body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] serving %s." cid (Uri.to_string uri));
      API.dispatcher request body
    in
    let conn_closed (_,cid) =
      let cid = Cohttp.Connection.to_string cid in
      Http_log.info (fun f -> f "[%s] closing" cid);
    in
    Serv.make ~conn_closed ~callback ()

end

module Main
    (Pclock: Mirage_types.PCLOCK)
    (Con: Conduit_mirage.S)
= struct

  module Http_srv = Cohttp_mirage.Server_with_conduit

  let start clock con =
    let module WmClock = struct
      let now = fun () ->
        let int_of_d_ps (d, ps) =
          d * 86_400 + Int64.(to_int (div ps 1_000_000_000_000L))
        in
        int_of_d_ps @@ Pclock.now_d_ps clock
    end in
    let module D = Dispatch(Http_srv)(WmClock) in
    Cohttp_mirage.Server_with_conduit.connect con >>= fun http_srv ->
    let http_port = Key_gen.http_port () in
    let tcp = `TCP http_port in
    Http_log.info (fun f -> f "listening on %d/TCP" http_port);
    (*http tcp @@ D.serve (D.redirect https_port)*)
    http_srv tcp D.serve
end
