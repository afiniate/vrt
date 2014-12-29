open Core.Std
open Async.Std

(** Provide reasonable, project specific abstractions for
    directories *)

val gather_dirs: String.t -> String.t List.t Deferred.t
(** Given a root directory traverses the director gathering the names *)

val change_to: String.t -> (Unit.t, Exn.t) Deferred.Result.t
(** A shim to allow Unix.chdir to fit into a Result based Deferred *)
