open Core.Std
open Async.Std

type errors =
  | No_project_root_indicator of String.t with sexp

exception Project_root_error of errors with sexp

(**
   This command provides functions to interact with vagrant and the vagrant environment
*)

val find: ?dominating:String.t -> Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Find the project root by a dominating file. By default the
    dominating file is 'Makefile' *)
