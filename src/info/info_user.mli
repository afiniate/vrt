open Core.Std
open Async.Std

(** A command that provides the users 'afiniate name' to the caller *)

exception Info_no_user

val name: String.t
val command: Command.t

val desc: String.t * Command.t
