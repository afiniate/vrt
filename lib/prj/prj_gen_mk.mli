open Core.Std
open Async.Std

(**
 * This command creates a `vrt.mk` file and optionally a `myocamlbuild`
 * in the project root when it is run
*)

exception Gen_mk_write_error

val name: String.t
val command: Command.t

val desc: String.t * Command.t
