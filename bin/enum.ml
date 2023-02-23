open Gcomp.Dashboard

let () =
  let y = Yojson.Safe.from_channel stdin in
  match of_yojson y with
  | Error e -> prerr_endline e
  | Ok {challenge; _} ->
    print_endline challenge.title;
    challenge.tasks |> List.iter (fun (t : task) ->
      print_endline t.title;
      print_endline t.statement
    )
