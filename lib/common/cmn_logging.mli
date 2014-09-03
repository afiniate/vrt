open Core.Std
open Async.Std

(** This module provides a console based logging abstraction for use
    with command line programs. *)

val log_level: Log.Level.t Command.Spec.Arg_type.t
(** A command arg that can be used as part of a command spec *)

val flag: Log.Level.t Command.Spec.param
(** A Command.Spec param that can be used in a Command spec. It binds
    `-l` and `--log-level` to a var `log_level` *)

val create: Log.Level.t -> Log.t
(** Create a logger to std out *)

val flush: Log.t -> (Unit.t, Exn.t) Deferred.Result.t
(** A helper function to help log flushing fit into Deferred.Result *)
