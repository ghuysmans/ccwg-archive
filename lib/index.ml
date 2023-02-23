type challenge = {
  are_results_final: bool;
  id: string;
  result_status: int;
  result_status_s: string [@key "result_status__str"];
  title: string;
} [@@deriving yojson {strict=false}]

type adventure = {
  challenges: challenge list;
  competition: int;
  competition_s: string [@key "competition__str"];
  id: string;
  title: string;
} [@@deriving yojson {strict=false}]

type t = {
  adventures: adventure list;
  current_time_ms: int;
} [@@deriving yojson]
