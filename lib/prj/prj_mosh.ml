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
  let logger = Trv.Log.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Log.debug logger "Starting vagrant ...";
  Trv.Log.flush logger
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>= fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Vrt_common.Aws.identity ()
  >>= fun identity ->
  Trv.Log.flush logger
  >>| fun _ ->
  Ok (mosh logger identity ip)

let spec =
  let open Command.Spec in
  empty
  +> Trv.Log.flag

let name = "mosh"

let command =
  Command.async_basic ~summary:"Run mosh to access the remote host"
    spec
    (fun log_level () ->
       Trv.Cmd.result_guard
         (fun _ -> do_mosh ~log_level))

let desc = (name, command)
