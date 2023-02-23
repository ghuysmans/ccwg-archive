let () = Lwt_main.run (
  let chall =
    let y = Yojson.Safe.from_file "data/_poll?p=e30" in
    let open Gcomp.Index in
    match of_yojson y with
    | Ok {adventures = l; _} -> List.concat (List.map (fun a -> a.challenges) l)
    | Error e -> failwith e
  in
  let base = "https://codejam.googleapis.com/dashboard/%s/poll?p=e30" ^^ "" in
  chall |> Lwt_list.iter_s (fun (c : Gcomp.Index.challenge) ->
    let fn = "data/challenge/" ^ c.id ^ ".json" in
    match%lwt Lwt_unix.file_exists fn with
    | false ->
      let%lwt () = Lwt_unix.sleep 1. in
      let uri = Printf.sprintf base c.id |> Uri.of_string in
      let%lwt resp, body = Cohttp_lwt_unix.Client.get uri in
      let%lwt raw = Cohttp_lwt.Body.to_string body in
      if Cohttp.Response.status resp = `OK then
        match Base64.(decode ~pad:false ~alphabet:uri_safe_alphabet raw) with
        | Error (`Msg e) -> Lwt_io.eprintf "%s: %s\n" c.id e
        | Ok data ->
          let open Lwt_io in
          let%lwt () = printf "%s %s\n" c.id c.title in
          let%lwt ch = open_file ~mode:Output fn in
          let%lwt () = write ch data in
          close ch
      else
        Lwt_io.eprintf "%s: bad HTTP status\n" c.id
    | true ->
      Lwt_io.eprintf "%s: dup\n" c.id
  )
)
