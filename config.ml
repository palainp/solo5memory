open Mirage

let port =
  let doc =
    Key.Arg.info
      ~doc:"The TCP port on which to listen for incoming connections."
      [ "port" ]
  in
  Key.(create "port" Arg.(opt ~stage:`Run int 8080 doc))

let addr =
  let doc = Key.Arg.info ~doc:"IP address to fetch" [ "addr" ] in
  Key.(create "addr" Arg.(opt ~stage:`Run string "127.0.0.1" doc))



(* uTCP *)

let tcpv4v6_direct_conf id =
  let packages_v = Key.pure [ package "utcp" ~sublibs:[ "mirage" ] ] in
  let connect _ modname = function
    | [_random; _mclock; _time; ip] ->
      Fmt.str "Lwt.return (%s.connect %S %s)" modname id ip
    | _ -> failwith "direct tcpv4v6"
  in
  impl ~packages_v ~connect "Utcp_mirage.Make"
    (random @-> mclock @-> time @-> ipv4v6 @-> (tcp: 'a tcp typ))

let direct_tcpv4v6
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time) id ip =
  tcpv4v6_direct_conf id $ random $ clock $ time $ ip

let net ?group name netif =
  let ethernet = etif netif in
  let arp = arp ethernet in
  let i4 = create_ipv4 ?group ethernet arp in
  let i6 = create_ipv6 ?group netif ethernet in
  let i4i6 = create_ipv4v6 ?group i4 i6 in
  let tcpv4v6 = direct_tcpv4v6 name i4i6 in
  let ipv4_only = Key.ipv4_only ?group () in
  let ipv6_only = Key.ipv6_only ?group () in
  direct_stackv4v6 ~tcp:tcpv4v6 ~ipv4_only ~ipv6_only netif ethernet arp i4 i6

let net = net "service" default_network

let main =
  main ~keys:[ Key.v port ; Key.v addr ] ~packages:[ package "duration" ]  "Unikernel.Main" (stackv4v6 @-> job)

let () =
  register "network" [ main $ net ]
