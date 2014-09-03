open Core.Std
open Core_extended.Std
open Async.Std

let repl logger dirs =
  let includes = List.fold ~init:"" ~f:(fun acc dir ->
      acc ^ " -I " ^ dir) dirs in
  Common.Unix.execvp
    ~prog:"sh"
    ~args:["-c";
           "utop -init build-support/lib/voteraise-init.ml " ^ includes]
    ()

let gather_dirs root =
  Common.Dirs.gather_dirs root
  >>= fun dirs ->
  return @@ Ok dirs

let do_repl log_level =
  let open Deferred.Result.Monad_infix in
  let logger = Common.Logging.create log_level in
  Prj_vagrant.project_root ()
  >>= fun project_root ->
  Common.Dirs.change_to project_root
  >>= fun _ ->
  gather_dirs @@ Filename.implode [project_root; "_build"; "server"; "lib"]
  >>= fun proj_dirs ->
  gather_dirs @@ Filename.implode [project_root; "_build"; "server"; "cmds"]
  >>= fun cmd_dirs ->
  repl logger (proj_dirs @ cmd_dirs);
  Log.info logger "Testing complete";
  Common.Logging.flush logger

let monitor_repl log_level () =
  Common.Cmd.result_guard
    (fun _ -> do_repl log_level)

let spec =
  let open Command.Spec in
  empty
  +> Common.Logging.flag

let name = "repl"

let command =
  Command.async_basic ~summary:"Runs a repl with everyhing needed for the project already loaded"
    spec
    monitor_repl

let desc = (name, command)
