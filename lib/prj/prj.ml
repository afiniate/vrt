open Core.Std
open Async.Std

let name = "prj"

let command =
  Command.group ~summary:"Project project tooling for the voteraise system"
    [(Prj_build_remote.name, Prj_build_remote.command)]

let desc = (name, command)
