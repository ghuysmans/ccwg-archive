type test = {
  name: string [@default ""];
  typ: int [@key "type"] [@default -1];
  type_s: string [@key "type__str"] [@default ""];
  value: int [@default 0];
} [@@deriving yojson {strict=false}]

type task = {
  analysis: string [@default ""];
  id: string;
  statement: string;
  task_type: int;
  task_type_s: string [@key "task_type__str"];
  tests: test list;
  title: string;
  trial_input_type: int [@default -1];
  trial_input_type_s: string [@key "trial_input_type__str"] [@default ""];
} [@@deriving yojson {strict=false}]

type challenge = {
  are_results_final: bool;
  id: string;
  recap: string [@default ""];
  result_status: int;
  result_status_s: string [@key "result_status__str"];
  tasks: task list;
  title: string;
} [@@deriving yojson {strict=false}]

type language = {
  id: int;
  id_s: string [@key "id__str"];
  name: string;
} [@@deriving yojson {strict=false}]

type t = {
  challenge: challenge;
  languages: language list;
} [@@deriving yojson]
