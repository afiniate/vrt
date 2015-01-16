open Core.Std
open Async.Std
open Async_unix.Std

let start_dynamodb () =
  Async_shell.sh "/opt/dynamodb/bin/dynamodb-test-server restart; sleep 5"
  >>= fun _ ->
  return @@ Ok ()

let stop_dynamodb () =
  Async_shell.sh "/opt/dynamodb/bin/dynamodb-test-server stop"
  >>= fun _ ->
  return @@ Ok ()

let do_cmd cmd () =
  Async_shell.sh ~verbose:true "%s" cmd
  >>= fun _ ->
  return @@ Ok ()

let do_test log_level cmd =
  let open Deferred.Result.Monad_infix in
  let logger = Common.Logging.create log_level in
  Prj_vagrant.project_root ()
  >>= Common.Dirs.change_to
  >>= fun _ ->
  Log.info logger "Running tests ";
  start_dynamodb ()
  >>= do_cmd cmd
  >>= stop_dynamodb
  >>= fun _ ->
  Log.info logger "Testing complete";
  Common.Logging.flush logger

let monitor_test log_level cmd () =
  Common.Cmd.result_guard
    (fun _ -> do_test log_level cmd)

let spec =
  let open Command.Spec in
  empty
  +> Common.Logging.flag
  +> anon ("cmd" %: string)

let name = "with-dynamodb"

let command =
  Command.async_basic ~summary:"Run the provided command (probably a test) with dynamodb"
    spec
    monitor_test

let desc = (name, command)
