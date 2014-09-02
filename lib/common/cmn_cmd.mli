open Core.Std
open Async.Std

(** Provide a useful functions for Async.Command interaction *)

val simply_print_response:
  exn:Exn.t ->
  (String.t Option.t Async_kernel.Deferred.t, Unit.t, String.t,
   String.t Option.t Async.Std.Deferred.t) format4 ->
  (Unit.t, Exn.t) Deferred.Result.t
(** Simply run the command and return the result as a deferred, or the
    exn result *)

val cmd_simply_print_response:
  name:String.t ->
  desc:String.t ->
  exn:Exn.t ->
  (String.t Option.t Async_kernel.Deferred.t, Unit.t, String.t,
   String.t Option.t Async.Std.Deferred.t) format4 ->
  String.t * Command.t
(** This provides a complete command that only runs the shell command
    and prints the result. *)

val result_guard: (Unit.t -> ('a, Exn.t) Deferred.Result.t) -> Unit.t Deferred.t
(** In the voteraise system its much more common to use
    Deferred.Result.t. However, the command infrastructure requires a
    deferred. This provides an automatic translation. It also Handles
    monitoring with `guard` as below *)

val guard: (Unit.t -> 'a Deferred.t) -> Unit.t Deferred.t
(** This provides a guard that can be used to return proper exit
    values to the Async command system. It also does a decent job of
    printing out common error messages *)
