open Lwt.Infix

let src = Logs.Src.create "memory_pressure" ~doc:"Memory pressure monitor"
module Log = (val Logs.src_log src : Logs.LOG)

module Main (S : Tcpip.Stack.V4V6) = struct

  let force_collection =
    let rec aux () =
      Log.info (fun f -> f "Collection");
      Gc.full_major ();
      Gc.compact ();
      Solo5_os.Time.sleep_ns (Duration.of_f 30.0) >>= fun () ->
      aux ()
    in
    aux ()

  let report_mem_usage =
    let used free total = total - free in

    let rec aux () =
      let { Solo5_os.Memory.free_words; heap_words; _ } = Solo5_os.Memory.stat () in
      let mem_total = heap_words * 8 in
      let mem_free = free_words * 8 in
      let mem_used = used mem_free mem_total in

      let { Solo5_os.Memory.free_words; heap_words; _ } = Solo5_os.Memory.quick_stat () in
      let mem_qtotal = heap_words * 8 in
      let mem_qfree = free_words * 8 in
      let mem_qused = used mem_qfree mem_qtotal in

      let {Gc.minor_words; promoted_words; major_words; minor_collections; major_collections; heap_words; heap_chunks; live_words; live_blocks; free_words; free_blocks; largest_free; fragments; compactions; top_heap_words; stack_size; forced_major_collections } = Gc.stat () in

      Log.info (fun f -> f "Solo5.Memory: [%d] quick used %dB/%dB / mallinfo used %dB/%dB / delta %d"
        0
        mem_qused mem_qtotal
        mem_used mem_total
        (mem_qused-mem_used)
      );

      Log.info (fun f -> f "Gc: [%d] heap %dB / live %dB / free %dB / top %dB / stack %dB"
        0
        (heap_words * 8) (live_words * 8) (free_words * 8)
        (top_heap_words * 8) (stack_size * 8)
      );

      Solo5_os.Time.sleep_ns (Duration.of_f 0.1) >>= fun () ->
      aux ()
    in
    aux ()
   
  let start s =
    let port = Key_gen.port () in
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
            S.TCP.close flow);

    S.listen s
end
