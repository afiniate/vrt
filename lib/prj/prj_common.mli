open Core.Std
open Async.Std

(** The goal of this module is to provide common project specific
    helper code to the various * commands provided in the tool *)

val search_dominating_file: base_dir:String.t -> dominating:String.t ->
  Unit.t -> String.t Option.t Deferred.t
(** Given a base directory and a dominating file this command
    searches up through * the directory structure looking for the
    dominating file *)
