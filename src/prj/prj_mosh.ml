open Core.Std
open Async.Std

let mosh logger identity ip =
  Common.Unix.execvp
    ~prog:"sh"
    ~args:["-c";
           "mosh ubuntu@" ^ ip ^ " --ssh=\"ssh -i " ^ identity ^"\""]
    ()

let do_mosh log_level =
  let open Deferred.Result.Monad_infix in
  let logger = Common.Logging.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Log.debug logger "Starting vagrant ...";
  Common.Logging.flush logger
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>= fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Common.Aws.identity ()
  >>= fun identity ->
  Common.Logging.flush logger
  >>| fun _ ->
  Ok (mosh logger identity ip)


let monitor_mosh log_level () =
  Common.Cmd.result_guard
    (fun _ -> do_mosh log_level)

let spec =
  let open Command.Spec in
  empty
  +> Common.Logging.flag

let name = "mosh"

let command =
  Command.async_basic ~summary:"Run mosh to access the remote host"
    spec
    monitor_mosh

let desc = (name, command)
