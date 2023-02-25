open Js_of_ocaml
open Js_of_ocaml_lwt

type challenge = Gcomp.Index.challenge = {
  are_results_final: bool;
  id: string;
  result_status: int;
  result_status_s: string [@key "result_status__str"];
  title: string;
} [@@deriving jsobject]

type adventure = Gcomp.Index.adventure = {
  challenges: challenge list;
  competition: int;
  competition_s: string [@key "competition__str"];
  id: string;
  title: string;
} [@@deriving jsobject]

type t = Gcomp.Index.t = {
  adventures: adventure list;
  current_time_ms: int;
} [@@deriving jsobject]


let () = Lwt.async (fun () ->
  let%lwt r = XmlHttpRequest.get "/adventures.json" in
  if r.code = 200 then
    match of_jsobject (Js.Unsafe.global##._JSON##parse r.content) with
    | Ok {adventures; _} ->
      adventures |> List.iter (fun a -> Printf.printf "%s %s\n" a.id a.title);
      Lwt.return ()
    | Error e ->
      prerr_endline e;
      Lwt.return ()
  else
    Lwt.return ()
)
