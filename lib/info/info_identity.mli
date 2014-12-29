open Core.Std
open Async.Std

(** A command that provides the correct pem file based on the users
    enviroment and aws configuration *)

val name: String.t
val command: Command.t

val desc: String.t * Command.t
