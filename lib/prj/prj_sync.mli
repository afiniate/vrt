open Core.Std
open Async.Std

(** Syncs the local project with the project on the remote vagrant
    host when run *)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
