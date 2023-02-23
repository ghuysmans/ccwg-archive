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
  match Sys.argv with
  | [| _ |]
  | [| _; "-h" |]
  | [| _; "-help" |]
  | [| _; "--help" |] ->
    Printf.eprintf "usage: %s FILE...\n" Sys.argv.(0);
    exit 1
  | _ ->
    List.tl (Array.to_list Sys.argv) |>
    List.iter (fun fn ->
      let y = Yojson.Safe.from_file fn in
      match Gcomp.Dashboard.of_yojson y with
      | Error e -> prerr_endline e
      | Ok {challenge = {recap; tasks; _}; _} ->
        extract recap;
        tasks |> List.iter (fun {Gcomp.Dashboard.analysis; statement; _} ->
          extract analysis;
          extract statement
        )
    )
