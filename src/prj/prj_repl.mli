open Core.Std
open Async.Std

(** Provides a repl that correctly starts an utop repl with all of the
    voteraise dependencies loaded *)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
