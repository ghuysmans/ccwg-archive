open Har

let () =
  let j = Yojson.Safe.from_channel stdin in
  match of_yojson j with
  | Error e -> prerr_endline e
  | Ok {log = {entries; _}} ->
    entries |> List.iter (fun (e : Entry.t) ->
      let p = Uri.path e.request.url in
      let ew = String.ends_with in
      if ew ~suffix:"poll" p || ew ~suffix:"poll_all" p then (
        let repl ~what ~by s = String.split_on_char what s |> String.concat by in
        let fn = repl ~what:'/' ~by:"_" (Uri.path_and_query e.request.url) in
        match e.response.content with
        | Some {text = Some raw; _} ->
          begin match Base64.(decode ~pad:false ~alphabet:uri_safe_alphabet raw) with
          | Ok x ->
            let ch = open_out ("data/" ^ fn) in
            output_string ch x;
            close_out ch
          | Error _ ->
            prerr_endline ("error decoding " ^ fn)
          end
        | _ ->
          prerr_endline ("no content for " ^ fn)
      )
    )
