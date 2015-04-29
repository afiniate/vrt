open Core.Std
open Async.Std

let mosh logger identity ip =
  Vrt_common.Unix.execvp
    ~prog:"sh"
    ~args:["-c";
           "mosh ubuntu@" ^ ip ^ " --ssh=\"ssh -i " ^ identity ^"\""]
    ()

let do_mosh ~log_level =
  let open Deferred.Result.Monad_infix in
  let logger = Log_common.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Log.debug logger "Starting vagrant ...";
  Log_common.flush logger
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>= fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Vrt_common.Aws.identity ()
  >>= fun identity ->
  Log_common.flush logger
  >>| fun _ ->
  Ok (mosh logger identity ip)

let spec =
  let open Command.Spec in
  empty
  +> Log_common.flag

let name = "mosh"

let command =
  Command.async_basic ~summary:"Run mosh to access the remote host"
    spec
    (fun log_level () ->
       Cmd_common.result_guard
         (fun _ -> do_mosh ~log_level))

let desc = (name, command)
