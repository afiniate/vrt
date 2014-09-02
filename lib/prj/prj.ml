open Core.Std
open Async.Std

let name = "prj"

let command =
  Command.group ~summary:"Project project tooling for the voteraise system"
    [Prj_build_remote.desc;
     Prj_copy_local.desc]

let desc = (name, command)
