open Core.Std
open Async.Std

(** This module provides ways to extract information from the afinate
    environment *)

val user: String.t Option.t
(** Get the afiniate user. At the moment this is the environment
   variable bound to AFINIATE_USER *)
