open Mirage

let port =
  let doc =
    Key.Arg.info
      ~doc:"The TCP port on which to listen for incoming connections."
      [ "port" ]
  in
  Key.(create "port" Arg.(opt ~stage:`Run int 8080 doc))

let main = main ~keys:[ Key.v port ] "Unikernel.Main" (stackv4v6 @-> job)
let stack = generic_stackv4v6 default_network
let () = register "network" [ main $ stack ]
