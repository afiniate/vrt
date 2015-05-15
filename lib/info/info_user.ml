open Core.Std
open Async.Std

exception Info_no_user

let do_get_user () =
  match Vrt_common.Aws.user with
  | Some user ->
    print_string user;
    return @@ Ok ()
  | None ->
    return @@ Error Info_no_user

let monitor_get_user () =
  Trv.Cmd.result_guard
    (fun _ -> do_get_user ())

let spec =
  let open Command.Spec in
  empty

let name = "aws-user"

let command =
  Command.async_basic ~summary:"Prints the current aws user if available"
    spec
    monitor_get_user

let desc = (name, command)
