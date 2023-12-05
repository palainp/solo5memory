open Lwt.Infix

let src = Logs.Src.create "memory_pressure" ~doc:"Memory pressure monitor"
module Log = (val Logs.src_log src : Logs.LOG)

module Main (S : Tcpip.Stack.V4V6) = struct

  let html = Cstruct.of_string
  "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">
   <html><head>
   <title>301 Moved Permanently</title>
   </head><body>
   <h1>Moved Permanently</h1>
   <p>The document has moved <a href=\"https://www.joedog.org/\">here</a>.</p>
   <hr>
   <address>Apache/2.2.31 (Amazon) Server at www.joedog.org Port 80</address>
   </body></html>"


  let start s =
    let port = Key_gen.port () in

(* The following is for testing connexions: [nc]->[unikernel] *)

    S.TCP.listen (S.tcp s) ~port (fun flow ->
        let dst, dst_port = S.TCP.dst flow in
        Logs.debug (fun f ->
            f "new tcp connection from IP %s on port %d" (Ipaddr.to_string dst)
              dst_port);
        S.TCP.read flow >>= function
        | Ok `Eof ->
            Logs.debug (fun f -> f "Closing connection!");
            Lwt.return_unit
        | Error e ->
            Logs.warn (fun f ->
                f "Error reading data from established connection: %a"
                  S.TCP.pp_error e);
            Lwt.return_unit
        | Ok (`Data b) ->
            Logs.debug (fun f ->
                f "read: %d bytes:\n%s" (Cstruct.length b) (Cstruct.to_string b));
            (* reply with a html hello world in any case *)
            S.TCP.write flow html ;
            S.TCP.close flow);

    S.listen s


end
