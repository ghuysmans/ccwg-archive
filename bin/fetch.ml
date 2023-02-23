open Soup

type res = {
  typ: [`Image | `File];
  uri: Uri.t;
  id: string;
  filename: string;
}

let extract_from_html html =
  let soup = parse html in
  let f ~elt ~attr typ =
    let prefix = "https://codejam.googleapis.com/dashboard/get_file/" in
    select elt soup |>
    to_list |>
    List.map (attribute attr) |>
    List.filter_map (fun x -> x) |> (* ignore missing attributes *)
    List.filter_map (fun x ->
      if String.starts_with ~prefix x then
        let uri = Uri.of_string x in
        match List.rev (String.split_on_char '/' (Uri.path uri)) with
        | filename :: id :: _ ->
          Some {
            id;
            typ;
            uri;
            filename;
          }
        | _ -> failwith "invalid get_file url"
      else
        None
    )
  in
  f ~elt:"a" ~attr:"href" `File @
  f ~elt:"img" ~attr:"src" `Image


let fetch_attachments ~store {Gcomp.Dashboard.recap; tasks; _} =
  let ana, stmt =
    let a, s =
      tasks |>
      List.map (fun {Gcomp.Dashboard.analysis; statement; _} ->
        extract_from_html analysis,
        extract_from_html statement
      ) |>
      List.split
    in
    List.concat a,
    extract_from_html recap @ List.concat s
  in
  let fetch_res base {uri; id; filename; _} =
    let fn = base ^ id ^ Filename.extension filename in
    if store then
      match%lwt Lwt_unix.file_exists fn with
      | false ->
        let%lwt () = Lwt_unix.sleep 1. in
        let%lwt resp, body = Cohttp_lwt_unix.Client.get uri in
        let%lwt data = Cohttp_lwt.Body.to_string body in
        if Cohttp.Response.status resp = `OK then
          let open Lwt_io in
          let%lwt () = printl id in
          let%lwt ch = open_file ~mode:Output fn in
          let%lwt () = write ch data in
          close ch
        else
          Lwt_io.eprintf "%s: bad HTTP status\n" id
      | true ->
        Lwt.return ()
    else
      Lwt_io.printl (Uri.to_string uri)
  in
  let%lwt () = Lwt_list.iter_s (fetch_res "data/file/") stmt in
  let%lwt () = Lwt_list.iter_s (fetch_res "data/file/analysis/") ana in
  Lwt.return ()

let load_challenge id =
  let fn = "data/challenge/" ^ id ^ ".json" in
  let y = Yojson.Safe.from_file fn in
  match Gcomp.Dashboard.of_yojson y with
  | Error e -> Lwt.fail_with e
  | Ok {challenge; _} -> Lwt.return challenge


let () = Lwt_main.run (
  let chall =
    let y = Yojson.Safe.from_file "data/_poll?p=e30" in
    let open Gcomp.Index in
    match of_yojson y with
    | Ok {adventures = l; _} -> List.concat (List.map (fun a -> a.challenges) l)
    | Error e -> failwith e
  in
  let fetch_json t (c : Gcomp.Index.challenge) =
    let base, fn =
      match t with
      | `Challenges ->
        "https://codejam.googleapis.com/dashboard/%s/poll?p=e30" ^^ "",
        "data/challenge/" ^ c.id ^ ".json"
      | `Scoreboards ->
        "https://codejam.googleapis.com/scoreboard/%s/poll?p=eyJtaW5fcmFuayI6MSwibnVtX2NvbnNlY3V0aXZlX3VzZXJzIjo1MH0",
        "data/scoreboard/" ^ c.id ^ ".json"
    in
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
      Lwt.return ()
  in
  match Sys.argv with
  | [| _; "challenges" |] -> chall |> Lwt_list.iter_s (fetch_json `Challenges)
  | [| _; "scoreboards" |] -> chall |> Lwt_list.iter_s (fetch_json `Scoreboards)
  | [| _; "attachments" |]
  | [| _; "list"; "attachments" |] ->
    let store = Array.length Sys.argv = 2 in
    chall |>
    Lwt_list.iter_s (fun (c : Gcomp.Index.challenge) ->
      let%lwt ch = load_challenge c.id in
      fetch_attachments ~store ch
    )
  | _ ->
    Printf.eprintf "usage: %s challenges|scoreboards|attachments\n" Sys.argv.(0);
    exit 1
)
