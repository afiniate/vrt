open Core.Std
open Core_extended.Std
open Async.Std

let repl logger dirs init_script =
  let includes = List.fold ~init:"" ~f:(fun acc dir ->
      acc ^ " -I " ^ dir) dirs in
  let init = match init_script with
    | Some script -> " -init " ^ script
    | None -> " " in
  Vrt_common.Unix.execvp
    ~prog:"sh"
    ~args:["-c";
           "utop  " ^ init ^ includes]
    ()

let gather_all_build_dirs build_dirs =
  Trv.Flib.Dir.gather_all_dirs build_dirs
  >>| fun dirs ->
  Ok dirs

let do_repl ~init_script ~build_dirs ~log_level =
  let open Deferred.Result.Monad_infix in
  let logger = Trv.Log.create log_level in
  Trv.Build.project_root ()
  >>= fun project_root ->
  Trv.Flib.Dir.change_to project_root
  >>= fun _ ->
  gather_all_build_dirs build_dirs
  >>= fun dirs ->
  repl logger dirs init_script;
  Log.info logger "Testing complete";
  Trv.Log.flush logger

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-i"] "--init" (optional string)
    ~doc:"init The init script (ml) for the toplevel"
  +> flag ~aliases:["-d"] "--include-dir" (listed string)
    ~doc:"include-dir The list of directories to include"
  +> Trv.Log.flag

let name = "repl"

let command =
  Command.async_basic ~summary:"Runs a repl with everyhing needed for the project already loaded"
    spec
    (fun init_script build_dirs log_level () ->
       Trv.Cmd.result_guard
         (fun _ -> do_repl ~init_script ~build_dirs ~log_level))

let desc = (name, command)
