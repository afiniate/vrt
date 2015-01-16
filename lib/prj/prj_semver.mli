open Core.Std
open Async.Std

(** This command uses git describe to create a valid semantic version *)

val get_semver: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Get the current semantic version of the project, assuming CWD is
    inside of said project *)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
