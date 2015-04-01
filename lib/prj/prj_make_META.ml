open Core.Std
open Core_extended.Std
open Async.Std

let format_cmds cmds =  "[\n" ^
                        (List.fold ~init:""
                           ~f:(fun acc el -> acc ^ "    [" ^ el ^ "]\n") cmds) ^
                        "]\n"

let format_build_cmds = function
  | [] -> format_cmds ["make build"]
  | build_cmds -> format_cmds build_cmds

let format_install_cmds = function
  | [] -> format_cmds ["make install"]
  | install_cmds -> format_cmds install_cmds

let format_remove_cmds = function
  | [] -> format_cmds ["make remove"]
  | remove_cmds -> format_cmds remove_cmds

let format_build_dependencies =
  List.fold ~init:""
    ~f:(fun acc el -> acc ^ " \"" ^ el ^ "\" {build}")

let write_meta target_dir name semver desc depends =
  let requires = (String.concat ~sep:" " depends)
                 ^ " " in
  let contents = "version = \"" ^ semver ^ "\"\n" ^
                 "description = \"" ^ desc ^ "\"\n" ^
                 "requires = \"" ^ requires ^ "\"\n" ^
                 "archive(byte) = \"" ^ name ^ ".cma\"\n" ^
                 "archive(byte, plugin) = \"" ^ name ^ ".cma\"\n" ^
                 "archive(native) = \"" ^ name ^ ".cmxa\"\n" ^
                 "archive(native, plugin) = \"" ^ name ^ ".cmxs\"" ^
                 "exists_if = \""^ name ^ ".cma\"\n" in
  Common.Files.write target_dir "META" contents

let do_make_meta ~name ~desc ~target_dir ~depends ~root_file =
  Prj_project_root.find ~dominating:root_file ()
  >>=? fun project_root ->
  Common.Dirs.change_to project_root
  >>=? fun _ ->
  Prj_semver.get_semver ()
  >>=? fun semver ->
  write_meta target_dir name semver desc depends

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-n"] "--name" (required string)
    ~doc:"name The name of the project"
  +> flag ~aliases:["-s"] "--desc" (required string)
    ~doc:"desc A short description of the project"
  +> flag ~aliases:["-z"] "--target-dir" (required string)
    ~doc:"target-dir The directory in which to generate the opam file"
  +> flag ~aliases:["-d"] "--depends" (listed string)
    ~doc:"depends A runtime dependency of the project"
  +> flag "--root-file" (optional_with_default "Makefile" string)
    ~doc:"root-file The file that identifies the project root. Probably 'Makefile' or 'Vagrantfile'"

let name = "make-meta"

let command =
  Command.async_basic ~summary:"Generates a valid `META` file"
    spec
    (fun name desc target_dir depends root_file () ->
       Common.Cmd.result_guard
        (fun _ -> do_make_meta ~name ~desc ~target_dir ~depends ~root_file))

let desc = (name, command)
