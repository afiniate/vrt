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
  let logger = Vrt_common.Logging.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Log.debug logger "Starting vagrant ...";
  Vrt_common.Logging.flush logger
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>= fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Vrt_common.Aws.identity ()
  >>= fun identity ->
  Vrt_common.Logging.flush logger
  >>| fun _ ->
  Ok (mosh logger identity ip)

let spec =
  let open Command.Spec in
  empty
  +> Vrt_common.Logging.flag

let name = "mosh"

let command =
  Command.async_basic ~summary:"Run mosh to access the remote host"
    spec
    (fun log_level () ->
       Vrt_common.Cmd.result_guard
         (fun _ -> do_mosh ~log_level))

let desc = (name, command)
