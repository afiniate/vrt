open Core.Std
open Async.Std

let name = "prj"

let command =
  Command.group ~summary:"Project project tooling for the ocaml systems"
    [Prj_build_remote.desc;
     Prj_copy_local.desc;
     Prj_mosh.desc;
     Prj_with_dynamodb.desc;
     Prj_repl.desc;
     Prj_make_dot_merlin.desc;
     Prj_make_opam.desc;
     Prj_sync.desc;
     Prj_semver.desc;
     Prj_gen_mk.desc]

let desc = (name, command)
