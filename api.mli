module Dispatch (H:Cohttp_lwt.S.Server)(Clock:Webmachine.CLOCK) : sig
  val dispatcher : Cohttp.Request.t -> Cohttp_lwt.Body.t
    -> (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t
end
