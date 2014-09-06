open Core.Std
open Async.Std

type error = Failed
exception Remote_error of error

type area =
  | Devops
  | Main


let do_ssh logger identity ip area command =
  let ssh = Async_shell.ssh
      ~ssh_options:["-i"; identity]
      ~user:"ubuntu"
      ~host:ip
      ~verbose:true in
  (match area with
   | Main ->
     ssh "cd /vagrant; source /home/ubuntu/.opam/opam-init/init.sh; PATH=$PATH:~/.cabal/bin; make %s"
       command
   | Devops ->
     ssh "cd /vagrant/devops; source /home/ubuntu/.opam/opam-init/init.sh;PATH=$PATH:~/.cabal/bin; make %s"
       command)
  >>| fun _ ->
  Ok ()

let do_build log_level area cmd =
  let logger = Common.Logging.create log_level in
  Prj_vagrant.project_root ()
  >>=? fun project_root ->
  Log.info logger "Project root is %s" project_root;
  Log.info logger "Starting vagrant ...";
  Common.Logging.flush logger
  >>= fun _ ->
  Common.Dirs.change_to project_root
  >>= fun _ ->
  Prj_vagrant.start_vagrant project_root
  >>=? fun ip ->
  Log.info logger "Remote IP is %s" ip;
  Common.Aws.identity ()
  >>=? fun identity ->
  Log.info logger "Syncing remote";
  Prj_vagrant.rsync ~identity ~project_root ~ip ()
  >>=? fun ip' ->
  Log.info logger "Running build command";
  do_ssh logger identity ip' area cmd
  >>=? fun _ ->
  Common.Logging.flush logger

let monitor_build log_level area cmd () =
  Common.Cmd.result_guard
    (fun _ -> do_build log_level area cmd)

let area_arg =
  Command.Spec.Arg_type.create
    (function
      | "devops" -> Devops
      | _ -> Main)

let spec =
  let open Command.Spec in
  empty
  +> Common.Logging.flag
  +> flag ~aliases:["-t"] "--target" (optional_with_default Main area_arg)
    ~doc:"target The target area. main or devops"
  +> anon (maybe_with_default "" ("cmd" %: string))

let readme () =
  "This builds the project on the remote box. It must be run in the project directory"

let name = "build-remote"

let command =
  Command.async_basic ~summary:"Builds the project on the remote vagrant box"
    ~readme
    spec
    monitor_build

let desc = (name, command)
