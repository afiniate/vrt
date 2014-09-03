open Core.Std
open Async.Std

(**
   This command provides functions to interact with vagrant and the vagrant environment
*)

type errors =
  | No_vagrant_file
  | Invalid_ip with sexp

exception Vagrant_error of errors with sexp

type ip = String.t

val project_root: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(**
 * Starting in the current directory search up through the project root
 * looking for the top level directory
*)

val remote_ip: Unit.t -> (ip, Exn.t) Deferred.Result.t
(**
 * Get the remote ip if it exists
*)

val start_vagrant: String.t -> (ip, Exn.t) Deferred.Result.t
(**
 * Start vagrant if possible
*)

val rsync: identity:String.t -> project_root:String.t ->
  ip:ip -> Unit.t -> (ip, Exn.t) Deferred.Result.t
(**
   Sync project dir to the vagrant environment
*)
