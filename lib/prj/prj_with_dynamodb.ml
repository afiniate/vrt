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

let do_test ~log_level ~cmd =
  let open Deferred.Result.Monad_infix in
  let logger = Log_common.create log_level in
  Prj_vagrant.project_root ()
  >>= Flib_dir.change_to
  >>= fun _ ->
  Log.info logger "Running tests ";
  start_dynamodb ()
  >>= do_cmd cmd
  >>= stop_dynamodb
  >>= fun _ ->
  Log.info logger "Testing complete";
  Log_common.flush logger

let spec =
  let open Command.Spec in
  empty
  +> Log_common.flag
  +> anon ("cmd" %: string)

let name = "with-dynamodb"

let command =
  Command.async_basic
    ~summary:"Run the provided command (probably a test) with dynamodb"
    spec
    (fun log_level cmd () ->
       Cmd_common.result_guard
         (fun _ -> do_test ~log_level ~cmd))

let desc = (name, command)
