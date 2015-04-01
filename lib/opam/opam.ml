open Core.Std
open Async.Std

let name = "opam"

let command =
  Command.group ~summary:"Opam opam specific tooling for the system"
    [Opam_make_opam.desc]

let desc = (name, command)
