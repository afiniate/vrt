open Core.Std
open Async.Std

(** Provide reasonable, project specific abstractions for
    directories *)

val gather_dirs: String.t -> String.t List.t Deferred.t
(** Given a root directory traverses the directory gathering the
    names *)

val gather_all_dirs: String.t List.t -> String.t List.t Deferred.t
(** Given a list of root directory traverses the each directory
    gathering the sub directories *)

val change_to: String.t -> (Unit.t, Exn.t) Deferred.Result.t
(** A shim to allow Unix.chdir to fit into a Result based Deferred *)
