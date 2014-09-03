open Core.Std
open Async.Std

(** Provide a useful functions for Async.Command interaction *)


val result_guard: (Unit.t -> ('a, Exn.t) Deferred.Result.t) -> Unit.t Deferred.t
(** In the voteraise system its much more common to use
    Deferred.Result.t. However, the command infrastructure requires a
    deferred. This provides an automatic translation. It also Handles
    monitoring with `guard` as below *)

val guard: (Unit.t -> 'a Deferred.t) -> Unit.t Deferred.t
(** This provides a guard that can be used to return proper exit
    values to the Async command system. It also does a decent job of
    printing out common error messages *)
