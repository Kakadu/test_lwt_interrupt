open Lwt.Syntax

exception It_was_interrupted

let handler _ _ = Lwt.return ()

(** Sleep for 5s, and interrupt after 2s *)
let schedule () =
  let task, res = Lwt.task () in

  Lwt.async (fun () ->
      Lwt.catch
        (fun () ->
          let* () = Lwt_io.printf "Inside a task\n%!" in
          let* () = task in
          let* () = Lwt_io.printf "Inside a task 2\n%!" in

          (* let* () = Lwt_unix.sleep 5. in *)
          Lwt.return ())
        (function
          | It_was_interrupted ->
              print_endline "interrupt gotten";
              Lwt.return ()
          | _ -> failwith "What to do here?"));

  let* () = Lwt_unix.sleep 2. in
  Lwt.wakeup_later_exn res It_was_interrupted;
  Lwt.return ()

let prefix = "./_build/default"
let http_port = 8888

let http_server =
  let open Cohttp_lwt_unix in
  let callback _conn req _body =
    let respond fname = Server.respond_file ~fname () in
    match Request.resource req with
    | "/" ->
        print_endline "HERR";
        respond (prefix ^ "/index.html")
    | s ->
        let _ = Sys.command "ls" in
        Printf.printf "queried %s\n%!" s;
        respond (prefix ^ s)
  in

  Format.printf "Creating http server on http://localhost:%d/ ...\n%!" http_port;
  Server.create ~mode:(`TCP (`Port http_port)) (Server.make ~callback ())

let ws_port = 6555

let () =
  let open Lwt in
  Format.printf "Creating WebSocker server on port %d ...\n%!" ws_port;
  (* printf "Creating WebSocker server on http://localhost:%d/ ...\n%!" cfg.ws_port; *)
  let server = Ws.Server.create ~port:ws_port in
  let on_connect _ = Lwt.return () in
  Lwt_main.run
    (let* () = schedule () in
     Ws.Server.run ~on_connect server handler <&> http_server)
