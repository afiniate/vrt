open Core.Std
open Async.Std

(** This module provides the command group for `prj` or project. Its
    simply an aggregator for all project commands *)

val name: String.t

val command: Command.t

val desc: String.t * Command.t
