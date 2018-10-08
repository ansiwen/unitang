open Lwt.Infix

module YB = Yojson.Basic

(* Logging *)
let api_src = Logs.Src.create "api" ~doc:"Tang REST API"
module Api_log = (val Logs.src_log api_src : Logs.LOG)

module Dispatcher (H:Cohttp_lwt.S.Server)(Clock:Webmachine.CLOCK) = struct
  let jsend_error msg =
    `Assoc [
      ("status", `String "error");
      ("message", `String msg)
    ]

  let string_rev s =
    let len = String.length s in
    String.init len (fun i -> s.[len - 1 - i])

  let strip_trailing_zeros s =
    let len = String.length s in
    let stop =
      let i = ref (len-1) in
      while !i >= 0 && s.[!i] = '\x00' do
        decr i
      done;
      !i
    in
    let len2 = ((stop+2)/2)*2 in
    if len2 < len then
      String.sub s 0 len2
    else
      s

  let b64_encode = B64.encode ~pad:true ~alphabet:B64.uri_safe_alphabet

  let b64_decode = B64.decode ~alphabet:B64.uri_safe_alphabet

  let b64_of_z z = Z.to_bits z |> strip_trailing_zeros |> string_rev |> b64_encode

  let z_of_b64 s = b64_decode s |> string_rev |> Z.of_bits

  let json_member s json =
    let m = YB.Util.member s json in
    match m with
      | `Null -> failwith ("Malformed JSON, missing member: " ^ s)
      | x -> x

  let json_string s json =
    let m = json_member s json in
    match m with
      | `String x -> x
      | _ -> failwith ("Malformed JSON, member " ^ s ^ " is not a string")

  (* let b64_of_z z = b64_encode (Z.to_bits z)

  let z_of_b64 s = Nocrypto.Numeric.Z. (b64_decode s) *)

  let adv_jws = Key_gen.adv_jws ()

  let crv, d_key =
    let data = YB.from_string (Key_gen.d_jwk ()) in
    let alg = json_string "alg" data in
    let crv = json_string "crv" data in
    let d = json_string "d" data |> z_of_b64 in
    let key_ops = json_member "key_ops" data |> YB.Util.to_list |> YB.Util.filter_string in
    let kty = json_string "kty" data in
    if not (alg = "ECMR") then
      failwith ("Unsupported algorithm: " ^ alg)
    else
    if not (List.mem "deriveKey" key_ops) then
      failwith ("key_ops does not contain deriveKey")
    else
    if not (kty = "EC") then
      failwith ("Unsupported key type: " ^ kty)
    else
    crv, d

  let crv_module =
    let c : (module Curve.S) = match crv with
    | "P-521" -> (module Curve.P521)
    | "P-224" -> (module Curve.P224)
    | "P-192" -> (module Curve.P192)
    | "X25519" -> (module Curve.C25519)
    | _ -> failwith ("Unsuported curve: " ^ crv)
    in
    c

  (* Apply the [Webmachine.Make] functor to the Lwt_unix-based IO module
   * exported by cohttp. For added convenience, include the [Rd] module
   * as well so you don't have to go reaching into multiple modules to
   * access request-related information. *)
  module Wm = struct
    module Rd = Webmachine.Rd
    include Webmachine.Make(H.IO)(Clock)
  end

  let add_common_headers (headers: Cohttp.Header.t): Cohttp.Header.t =
    Cohttp.Header.add_list headers [
      ("access-control-allow-origin", "*");
      ("access-control-allow-headers", "Accept, Content-Type, Authorization");
      ("access-control-allow-methods", "GET, HEAD, POST, DELETE, OPTIONS, PUT, PATCH")
    ]

  class advertise = object(self)
    inherit [Cohttp_lwt.Body.t] Wm.resource

    method private to_json rd =
      Wm.continue (`String adv_jws) rd

    method! allowed_methods rd =
      Wm.continue [`GET] rd

    method content_types_provided rd =
      Wm.continue [
        "application/jose+json", self#to_json
      ] rd

    method content_types_accepted rd =
      Wm.continue [] rd
  end

  (** A resource for recovery via POST. *)
  class recover = object
    inherit [Cohttp_lwt.Body.t] Wm.resource

    val mutable x_req = Z.zero
    val mutable y_req = Z.zero
    val mutable is_derive_key = true

    method! allowed_methods rd =
      Wm.continue [`POST] rd

    method content_types_provided rd =
      Wm.continue [
        "application/jwk+json", Wm.continue (`Empty);
      ] rd

    method content_types_accepted rd =
      Wm.continue [] rd

    method! malformed_request rd =
      begin try
        Cohttp_lwt.Body.to_string rd.Wm.Rd.req_body
        >>= fun body ->
        Api_log.debug (fun f -> f "Request body:\n%s" body);
        let data = YB.from_string body in
        let alg = json_string "alg" data in
        let crv_req = json_string "crv" data in
        let kty = json_string "kty" data in
        if not (alg = "ECMR") then
          failwith ("Unsupported algorithm: " ^ alg)
        else
        if not (kty = "EC") then
          failwith ("Unsupported key type: " ^ kty)
        else
        if not (crv_req = crv) then
          failwith ("Curve doesn't match: " ^ crv_req)
        else
        let key_ops = YB.Util.member "key_ops" data in
        is_derive_key <- begin match key_ops with
          | `List l -> YB.Util.filter_string l |> List.mem "deriveKey"
          | `Null -> true
          | _ -> false
          end;
        x_req <- json_string "x" data |> z_of_b64;
        y_req <- json_string "y" data |> z_of_b64;
        Wm.continue false rd
      with
        | e ->
          let json = (Printexc.to_string e |> jsend_error) in
          let resp_body = `String (YB.to_string ~std:true json) in
          Wm.continue true { rd with Wm.Rd.resp_body }
      end

    method! forbidden rd =
      Wm.continue (not is_derive_key) rd

    method! process_post rd =
      begin try
        let (module Crv) = crv_module in
        let x, y = Crv.multiply d_key (x_req, y_req) in
        let response = `Assoc [
          ("alg", `String "ECMR");
          ("crv", `String crv);
          ("key_ops", `List [ `String "deriveKey" ]);
          ("kty", `String "EC");
          ("x", `String (b64_of_z x));
          ("y", `String (b64_of_z y));
        ] in
        Lwt.return (response, true)
      with
        | e -> Lwt.return ((Printexc.to_string e |> jsend_error), false)
      end
      >>= fun (json, ok) ->
      let resp_body = `String (YB.to_string ~std:true json) in
      Wm.continue ok { rd with Wm.Rd.resp_body }

  end (* recover *)

  let dispatch request body =
    let open Cohttp in
    (* Perform route dispatch. If [None] is returned, then the URI path did
    not match any of the route patterns. In this case the server should
    return a 404 [`Not_found]. *)
    Api_log.debug (fun f ->
      f "Request header:\n%s" (Request.headers request |> Header.to_string));
    let routes = [
      ("/adv", fun () -> new advertise) ;
      ("/adv/:id", fun () -> new advertise) ;
      ("/rec/:id", fun () -> new recover) ;
    ] in
    let meth = Request.meth request in
    begin match meth with
      | `OPTIONS -> Lwt.return (Some (`OK, Header.init (), `Empty, [])) (* OPTIONS always ok *)
      | _ -> Wm.dispatch' routes ~body ~request
    end
    >|= begin function
        | None        -> (`Not_found, Header.init (), `String "Not found", [])
        | Some result -> result
    end
    >>= fun (status, headers, body, path) ->
      let headers = add_common_headers headers in
      Api_log.info (fun f -> f "%d - %s %s"
        (Code.code_of_status status)
        (Code.string_of_method (Request.meth request))
        (Uri.path (Request.uri request)));
      Api_log.debug (fun f ->
        f "Webmachine path: %s" (String.concat ", " path));
      Api_log.debug (fun f ->
        f "Response header:\n%s" (Header.to_string headers));
      Api_log.debug (fun f ->
        let resp_body = match body with
          | `Empty | `String _ | `Strings _ as x -> Body.to_string x
          | `Stream _ -> "__STREAM__"
        in
        f "Response body:\n%s" resp_body);
      (* Finally, send the response to the client *)
      H.respond ~headers ~body ~status ()
end
