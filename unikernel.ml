open Lwt.Infix

let src = Logs.Src.create "memory_pressure" ~doc:"Memory pressure monitor"
module Log = (val Logs.src_log src : Logs.LOG)

module Main (S : Tcpip.Stack.V4V6) = struct

  let http = Cstruct.of_string
  "HTTP/1.1 200 OK\r\n
   content-type: text/html; charset=utf-8\r\n
   content-Length: 292\r\n
   <!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">
   <html><head>
   <title>Hello world</title>
   </head><body>
   <h1>Hello world</h1>
   <p>Hello world.</p>
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
            S.TCP.write flow http ;
            S.TCP.close flow);

    S.listen s


end
