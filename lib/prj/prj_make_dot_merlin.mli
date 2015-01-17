open Core.Std
open Async.Std

(**
 * This command creates a `.merlin` file in the project root when it is run
*)

exception Dot_merlin_write_error

val name: String.t
val command: Command.t

val desc: String.t * Command.t
