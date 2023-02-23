open Soup

let extract html =
  let soup = parse html in
  let show = function
    | None -> ()
    | Some url ->
      let prefix = "https://codejam.googleapis.com/dashboard/get_file/" in
      if String.starts_with ~prefix url then
        print_endline url
  in
  select "a" soup |> iter (fun x -> show (attribute "href" x));
  select "img" soup |> iter (fun x -> show (attribute "src" x))

let () =
  let y = Yojson.Safe.from_channel stdin in
  match Gcomp.Dashboard.of_yojson y with
  | Error e -> prerr_endline e
  | Ok {challenge = {recap; tasks; _}; _} ->
    extract recap;
    tasks |> List.iter (fun {Gcomp.Dashboard.analysis; statement; _} ->
      extract analysis;
      extract statement
    )
