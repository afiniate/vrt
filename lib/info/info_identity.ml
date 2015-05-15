open Core.Std
open Async.Std

let do_identity () =
  let open Deferred.Result.Monad_infix in
  Vrt_common.Aws.identity ()
  >>= fun identity ->
  print_string identity;
  return @@ Ok ()

let monitor_identity () =
  Trv.Cmd.result_guard
    (fun _ -> do_identity ())

let spec =
  let open Command.Spec in
  empty

let name = "identity"

let command =
  Command.async_basic ~summary:"Get the valid pem file to access the aws instance"
    spec
    monitor_identity

let desc = (name, command)
