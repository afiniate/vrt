open Core.Std
open Async.Std

(** This module provides the command group for `opam`. It provides a
    set of commands that help for interaction with opam *)


val name: String.t

val command: Command.t

val desc: String.t * Command.t
