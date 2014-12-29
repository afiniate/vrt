open Core.Std
open Async.Std

(** This command implements building on a remote node. It has to be
    run in a vagrant directory*)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
