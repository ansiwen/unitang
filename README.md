# UniTang

This is the implementation of a [tang](https://github.com/latchset/tang)
server as a unikernel, based on [MirageOS](https://mirage.io/), a unikernel
framework entirely written in the statically typed functional language
[OCaml](https://ocaml.org/).

It's still in an early state and only supports one server key at the moment.

## Building

You have to have the ocaml package manager [opam](https://opam.ocaml.org/)
installed. Then for example:

```
$ opam install mirage
$ mirage configure -t unix --net socket
$ make depend
$ make
$ ./unitang --help

unitang(1)                      Unitang Manual                      unitang(1)



NAME
       unitang

SYNOPSIS
       unitang [OPTION]...

UNIKERNEL PARAMETERS
       --ips=IPS (absent=0.0.0.0)
           The IPv4 addresses bound by the socket in the unikernel.

       -l LEVEL, --logs=LEVEL (absent MIRAGE_LOGS env)
           Be more or less verbose. LEVEL must be of the form *:info,foo:debug
           means that that the log threshold is set to info for every log
           sources but the foo which is set to debug.

       --socket=SOCKET
           The IPv4 address bound by the socket in the unikernel.

APPLICATION OPTIONS
       --adv=VAL (required)
           The advertised jws containing the public key of the deriving key.
           This key is required.

       --dkey=VAL (required)
           The jwk of the deriving key. This key is required.

       --port=VAL (absent=8080)
           Listening HTTP port.

OPTIONS
       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

ENVIRONMENT
       These environment variables affect the execution of unitang:

       MIRAGE_LOGS
           See option --logs.



Unitang                                                             unitang(1)

$ MIRAGE_LOGS=debug ./unitang --adv $(cat db/adv.jws) --dkey $(cat db/EIO0CuWE-3AeBlnkqmsr8flT_ks.jwk)
2018-10-04 18:21:34 +02:00: INF [tcpip-stack-socket] Manager: connect
2018-10-04 18:21:34 +02:00: INF [tcpip-stack-socket] Manager: configuring
2018-10-04 18:21:34 +02:00: INF [http] listening on 8080/TCP
...
```
For how to create the JWS and JWK files, refer to the
[tang](https://github.com/latchset/tang) documentation.


In another shell:
```
$ echo UniTangRulez | clevis encrypt tang '{"url": "http://localhost:8080"}' > secret.jwe
The advertisement contains the following signing keys:

qhjjYdwJOoXdBa0JMXJJxCU_ZMw

Do you wish to trust these keys? [ynYN] y
$ clevis decrypt < secret.jwe 
UniTangRulez
$
```

According output of unitang:
```
$ MIRAGE_LOGS=debug ./unitang --adv $(cat db/adv.jws) --dkey $(cat db/EIO0CuWE-3AeBlnkqmsr8flT_ks.jwk)
2018-10-04 18:30:18 +02:00: INF [tcpip-stack-socket] Manager: connect
2018-10-04 18:30:18 +02:00: INF [tcpip-stack-socket] Manager: configuring
2018-10-04 18:30:18 +02:00: INF [http] listening on 8080/TCP
2018-10-04 18:30:57 +02:00: INF [http] [1] serving //localhost:8080/adv/.
2018-10-04 18:30:57 +02:00: DBG [api] Request header:
accept: */*
host: localhost:8080
user-agent: curl/7.59.0


2018-10-04 18:30:57 +02:00: INF [api] 200 - GET /adv/
2018-10-04 18:30:57 +02:00: DBG [api] Webmachine path: v3b13, v3b12, v3b11, v3b10, v3b9, v3b8, v3b7, v3b6, v3b5, v3b4, v3b3, v3c3, v3c4, v3d4, v3e5, v3f6, v3g7, v3g8, v3h10, v3i12, v3l13, v3m16, v3n16, v3o16, v3o18
2018-10-04 18:30:57 +02:00: DBG [api] Response header:
access-control-allow-headers: Accept, Content-Type, Authorization
access-control-allow-methods: GET, HEAD, POST, DELETE, OPTIONS, PUT, PATCH
access-control-allow-origin: *
content-type: application/jose+json
vary: Accept, Accept-Encoding, Accept-Charset, Accept-Language


2018-10-04 18:30:57 +02:00: DBG [api] Response body:
{"payload":"eyJrZXlzIjpbeyJhbGciOiJFQ01SIiwiY3J2IjoiUC01MjEiLCJrZXlfb3BzIjpbImRlcml2ZUtleSJdLCJrdHkiOiJFQyIsIngiOiJBQ0FjMlJET0pBZVpXYUJfZWZKMFhhUVhrdmlWVWl3Yk5DZlVnUklhdnFBb1FMRzlLQ3pTNzBaVVdnOWlJM3UyMThTcUJadkY3cXc5eThpR0RqOUVGUS1iIiwieSI6IkFOMFRqZ1kyQ3Judmo5eHhfUHotUXpkOVJZUnJ5RlRkVDJpbS1pdGJtdlhmRENsRTU4M2tyNjNRamdMVmZNQ1lONXQwVHd0YWFNSVNCd1JqOFRXOWpWN3MifSx7ImFsZyI6IkVTNTEyIiwiY3J2IjoiUC01MjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJrdHkiOiJFQyIsIngiOiJBTHVqRnUzRFpJQUFqVGl5cnE2N0ctSEZ6T3BvQU5RSHVYaHBYR0VHQUs4aWJldy1wOUFwOHhpWjlwTEVPRVRIenFYOWpQRFlPOWtxRW5nbHl2X3FpZVpaIiwieSI6IkFLTC1oN2p4Q3dzNmJLdE9TNHI1MmRwRUkxVTJHOThHTThyLU4zNC0zRldNd0FRdGlBdXR1NTBiYjRJNUphSU9QUkkzSnllcUpFbXk4ajcwdk52QTA3TVAifV19","protected":"eyJhbGciOiJFUzUxMiIsImN0eSI6Imp3ay1zZXQranNvbiJ9","signature":"AMZUI3l-A6pbGAIMlQ9KQmF3Qy_VsDzE_UW2fZnxl34S6Hril3SkcG5RBdFktmfx9FiOtiR6hmLb6w3LRDJMShzkAFRrBKlGtifKP6R8dbh-MlXkn3vKy1gNwspBYo9ErEClvwmSZ80Bq99whjPOsdI_DODh54Ct5II1L9pmuxUrVtLV"}
2018-10-04 18:30:57 +02:00: INF [http] [1] closing
2018-10-04 18:32:17 +02:00: INF [http] [2] serving //localhost:8080/rec/EIO0CuWE-3AeBlnkqmsr8flT_ks.
2018-10-04 18:32:17 +02:00: DBG [api] Request header:
accept: */*
content-length: 230
content-type: application/jwk+json
host: localhost:8080
user-agent: curl/7.59.0


2018-10-04 18:32:17 +02:00: DBG [api] Request body:
{"alg":"ECMR","crv":"P-521","kty":"EC","x":"AZvSWTtsxIVRQAYoURTVMAOUDXzdPYkrNI4X69ET2n9bXFhtga_JHNY3KOuH9lvqNSaJ7NTkXgJZZATC4_qXMCJQ","y":"ARiaxRnfhX0HuBrwd31yQX2Me9ANxeZ-1rTc-DRYSWCVVp-rFLF8TV_VwRi4oFWM6ljR4mFAYZvllH9Q_sEtGKMO"}

2018-10-04 18:32:17 +02:00: INF [api] 200 - POST /rec/EIO0CuWE-3AeBlnkqmsr8flT_ks
2018-10-04 18:32:17 +02:00: DBG [api] Webmachine path: v3b13, v3b12, v3b11, v3b10, v3b9, v3b8, v3b7, v3b6, v3b5, v3b4, v3b3, v3c3, v3c4, v3d4, v3e5, v3f6, v3g7, v3g8, v3h10, v3i12, v3l13, v3m16, v3n16, v3n11, v3p11, v3o20, v3o18
2018-10-04 18:32:17 +02:00: DBG [api] Response header:
access-control-allow-headers: Accept, Content-Type, Authorization
access-control-allow-methods: GET, HEAD, POST, DELETE, OPTIONS, PUT, PATCH
access-control-allow-origin: *
content-type: application/jwk+json
vary: Accept, Accept-Encoding, Accept-Charset, Accept-Language


2018-10-04 18:32:17 +02:00: DBG [api] Response body:
{"alg":"ECMR","crv":"P-521","key_ops":["deriveKey"],"kty":"EC","x":"AWo5ZMji0DtEBolLXQYzHBPCX99UBsIkOzt7TNTczaUzsQd8CrdKI0UMSh0NxqTWq5_trq-mKRVBh_ejpsk8ZZ5R","y":"AU9ltb9k_YsOOCFw-bR40yRIkU5wRMF7EPHAmnPGIQK6LWiiQqlVO4gE0jlYTCGAnkzrawnSj6INEBqkptvjdvfL"}
2018-10-04 18:32:17 +02:00: INF [http] [2] closing
...
```
