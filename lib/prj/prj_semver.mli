open Core.Std
open Async.Std

(** This command uses git describe to create a valid semantic version *)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
