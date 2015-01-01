open Core.Std
open Core_extended.Std
open Async.Std

exception Opam_write_error

let write root name contents =
  let path = Filename.implode [root; name] in
  try
    Writer.save path ~contents
    >>| fun _ ->
    Ok ()
  with exn ->
    return @@ Result.Error Opam_write_error

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

let format_dependencies =
  List.fold ~init:""
    ~f:(fun acc el -> acc ^ " \"" ^ el ^ "\"")

let write_opam project_root name semver license maintainer author
    homepage bug_reports dev_repo build_cmds install_cmds remove_cmds depends
    build_depends =
  let maintainer_str = match maintainer with
    | Some m -> "maintainer: \"" ^ m ^ "\"\n"
    | None -> "" in
  let author_str = match author with
    | Some a -> "author: \"" ^ a ^ "\"\n"
    | None -> "" in
  let homepage_str = match homepage with
    | Some h -> "homepage: \"" ^ h ^ "\"\n"
    | None -> "" in
  let bug_str = match bug_reports with
    | Some b -> "bug-reports: \"" ^ b ^ "\"\n"
    | None -> "" in
  let contents = "opam-version: \"1.2\"\n" ^
                 "name: \"" ^ name ^ "\"\n" ^
                 "version: \"" ^ semver ^ "\"\n" ^
                 maintainer_str ^
                 author_str ^
                 homepage_str ^
                 bug_str ^
                 "license: \"" ^ license ^ "\"\n" ^
                 "dev-repo: \"" ^ dev_repo ^ "\"\n" ^
                 "\n" ^
                 "build: " ^ (format_build_cmds build_cmds) ^ "\n" ^
                 "install: " ^ (format_install_cmds install_cmds) ^ "\n" ^
                 "remove: " ^ (format_remove_cmds remove_cmds) ^ "\n" ^
                 "\n" ^
                 "depends: [" ^ ((format_build_dependencies build_depends) ^
                                 (format_dependencies depends)) ^ "]\n" in
  write project_root "opam" contents

let write_meta lib_dir name semver desc depends =
  let requires = (List.fold ~init:"" ~f:(fun acc el -> acc ^ " " ^ el) depends)
                 ^ " " in
  let contents = "version = \"" ^ semver ^ "\"\n" ^
                 "description = \"" ^ desc ^ "\"\n" ^
                 "requires = \"" ^ requires ^ "\"\n" ^
                 "archive(byte) = \"" ^ name ^ ".cma\"\n" ^
                 "archive(byte, plugin) = \"" ^ name ^ ".cma\"\n" ^
                 "archive(native) = \"" ^ name ^ ".cmxa\"\n" ^
                 "archive(native, plugin) = \"" ^ name ^ ".cmxs\"" ^
                 "exists_if = \""^ name ^ ".cma\"\n" in
  write lib_dir "META" contents

  let do_make_opam name desc license lib_dir no_meta maintainer author
      homepage bug_reports dev_repo build_cmds install_cmds remove_cmds depends
      build_depends =
    Prj_vagrant.project_root ()
    >>=? fun project_root ->
    Common.Dirs.change_to project_root
    >>=? fun _ ->
    Prj_semver.get_semver ()
    >>=? fun semver ->
    write_opam project_root name semver license maintainer author
      homepage bug_reports dev_repo build_cmds install_cmds remove_cmds depends
      build_depends
    >>=? fun _ ->
    write_meta lib_dir name semver desc depends

let monitor_make_opam name (desc:String.t) license lib_dir no_meta maintainer author
    homepage bug_reports dev_repo build_cmds install_cmds remove_cmds (depends: String.t List.t)
    build_depends () =
  Common.Cmd.result_guard
    (fun _ -> do_make_opam name desc license lib_dir no_meta maintainer author
        homepage bug_reports dev_repo build_cmds install_cmds remove_cmds depends
        build_depends)

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-n"] "--name" (required string)
    ~doc:"name The name of the project"
  +> flag ~aliases:["-s"] "--desc" (required string)
    ~doc:"desc A short description of the project"
  +> flag ~aliases:["-l"] "--license" (required string)
    ~doc:"license The license for this project"
  +> flag ~aliases:["-z"] "--lib-dir" (required string)
    ~doc:"lib-dir The main library dir for the project - For the META file"
  +> flag ~aliases:["-e"] "--no-meta" (optional_with_default false bool)
    ~doc:"no-meta Turn off meta generation for this project"
  +> flag ~aliases:["-m"] "--maintainer" (optional string)
    ~doc:"maintainer The maintainer of this library"
  +> flag ~aliases:["-a"] "--author" (optional string)
    ~doc:"author The author of this library"
  +> flag ~aliases:["-h"] "--homepage" (optional string)
    ~doc:"homepage The www homepage of the project"
  +> flag ~aliases:["-u"] "--bug-reports" (optional string)
    ~doc:"bug-reports The place to report bugs for the project"
  +> flag ~aliases:["-g"] "--dev-repo" (required string)
    ~doc:"dev-repo The development repo for this project"
  +> flag ~aliases:["-b"] "--build-cmd" (listed string)
    ~doc:"build-command A build command to run"
  +> flag ~aliases:["-i"] "--install-cmd" (listed string)
    ~doc:"install-command An install command to run"
  +> flag ~aliases:["-r"] "--remove-cmd" (listed string)
    ~doc:"remove-command A remove command to run"
  +> flag ~aliases:["-d"] "--depends" (listed string)
    ~doc:"depends A runtime dependency of the project"
  +> flag ~aliases:["-c"] "--build-depends" (listed string)
    ~doc:"build-depends A build time dependency of the project"

let name = "make-opam"

let command =
  Command.async_basic ~summary:"Generates a valid `opam` and `META` filey"
    spec
    monitor_make_opam

let desc = (name, command)
