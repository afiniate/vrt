open Core.Std
open Async.Std

let do_sync ~log_level =
  let open Deferred.Result.Monad_infix in
  let logger = Trv.Log.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Log.info logger "Project root is %s" project_root;
  Log.info logger "Starting vagrant ...";
  Trv.Log.flush logger
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>= fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Vrt_common.Aws.identity ()
  >>= fun identity ->
  Log.info logger "Syncing remote";
  Prj_vagrant.rsync ~identity ~project_root ~ip ()
  >>= fun _ ->
  Trv.Log.flush logger

let spec =
  let open Command.Spec in
  empty
  +> Trv.Log.flag

let name = "sync"

let command =
  Command.async_basic ~summary:"Syncs the local project dir to the remote vagrant host"
    spec
    (fun log_level () ->
       Trv.Cmd.result_guard
         (fun _ -> do_sync ~log_level))



let desc = (name, command)
