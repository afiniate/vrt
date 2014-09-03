open Core.Std
open Async.Std

(** Provides a command wrapper that starts up the dynamodb test
    instance. This will only work on a properly setup host a (devbox or ci
    server)
*)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
