open Core.Std
open Async.Std

(** Provide information specific to AWS and more specifically to the
    afiniate devbox setup *)

type errors =
  | Unable_to_find_region
  | Invalid_identity with sexp

exception Aws_error of errors with sexp

val identity: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Get the valid pem file for the current aws region *)

val region: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Get the currently configured default aws region *)
