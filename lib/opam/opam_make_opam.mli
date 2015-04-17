open Core.Std
open Async.Std

(**
 * This command creates an `opam` and `META` file for opam
*)

val name: String.t
val command: Command.t

val desc: String.t * Command.t

val write_opam: ?name:String.t -> ?semver:String.t
  -> target_dir:String.t
  -> license:String.t -> maintainer:String.t Option.t -> author:String.t Option.t
  -> homepage:String.t Option.t -> bug_reports:String.t Option.t -> dev_repo:String.t
  -> build_cmds:String.t List.t -> install_cmds:String.t List.t
  -> remove_cmds:String.t List.t -> depends:String.t List.t
  -> build_depends:String.t List.t -> Unit.t -> (Unit.t, Exn.t) Deferred.Result.t
