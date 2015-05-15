open Core.Std
open Async.Std

let name = "prj"

let command =
  Command.group ~summary:"Project tooling for the ocaml systems on AWS"
    [Prj_build_remote.desc;
     Prj_copy_local.desc;
     Prj_mosh.desc;
     Prj_with_dynamodb.desc;
     Prj_repl.desc;
     Prj_sync.desc]


let desc = (name, command)
