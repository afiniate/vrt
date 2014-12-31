open Core.Std
open Async.Std

exception Info_no_user

let do_get_user () =
  match Common.Afiniate.user with
  | Some user ->
    print_string user;
    return @@ Ok ()
  | None ->
    return @@ Error Info_no_user

let monitor_get_user () =
  Common.Cmd.result_guard
    (fun _ -> do_get_user ())

let spec =
  let open Command.Spec in
  empty

let name = "afiniate-user"

let command =
  Command.async_basic ~summary:"Prints the current afiniate user if available"
    spec
    monitor_get_user

let desc = (name, command)
