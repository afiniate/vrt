open Core.Std
open Async.Std

let command =
  Command.group ~summary:"Base tooling system for aws based projects"
  [Prj.desc;
   Env_info.desc]

let () =
  Command.run ~version:"1.0" ~build_info:"" command
