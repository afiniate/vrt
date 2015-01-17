open Core.Std
open Async.Std

(**
 * Provides commands that provide information about the system and environment
*)

val name: String.t

val command: Command.t

val desc: String.t * Command.t
