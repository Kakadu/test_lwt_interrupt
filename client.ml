(** Copyright 2022, Winnie Pooh *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Js_of_ocaml
open Firebug
open Js_of_ocaml.WebSockets

let () = assert (WebSockets.is_supported ())

let () =
  let sock = new%js webSocket (Js.string "ws://localhost:6555") in
  sock##.onopen :=
    Dom.handler (fun _e ->
        console##log (Js.string "opened");
        sock##send (Js.string "ping");
        Js._true);

  sock##.onmessage :=
    Dom.handler (fun e ->
        console##log_2 (Js.string "onmessage:") e##.data;
        Js._true)
