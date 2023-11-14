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

let main =
  main ~keys:[ Key.v port ; Key.v addr ] ~packages:[ package "duration" ]  "Unikernel.Main" (stackv4v6 @-> job)

let () =
  let stack = generic_stackv4v6 default_network in
  register "network" [ main $ stack ]
