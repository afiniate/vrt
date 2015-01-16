open Core.Std
open Async.Std

type error = No_aws_user
exception Copy_error of error

val name: String.t
val command: Command.t

val desc: String.t * Command.t
