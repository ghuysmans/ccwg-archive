open Gcomp.Index

let () =
  let y = Yojson.Safe.from_channel stdin in
  match of_yojson y with
  | Error e -> prerr_endline e
  | Ok {adventures; _} ->
    adventures |> List.iter (fun a ->
      print_endline (a.id ^ "\t" ^ a.title)
    )
