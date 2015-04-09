open Core.Std
open Core_extended.Std
open Async.Std

let format_cmd_strings cmds =  "[\n" ^
                        (List.fold ~init:""
                           ~f:(fun acc el -> acc ^ "    [" ^ el ^ "]\n") cmds) ^
                        "]\n"

let format_cmds
  : default:String.t List.t -> String.t List.t -> String.t =
  fun ~default cmds ->
    match cmds with
    | [] -> format_cmd_strings default
    | _ -> format_cmd_strings cmds

let format_build_cmds =
  format_cmds ~default:["make build"]

let format_install_cmds =
  format_cmds ~default:["make install"]

let format_remove_cmds =
  format_cmds ~default:["make remove"]

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
  Afin.Files.dump ~dir:target_dir ~name:"META" ~contents

let get_semver
  : String.t Option.t -> (String.t, Exn.t) Deferred.Result.t =
  function
  | Some semver ->
    return @@ Ok semver
  | None ->
    Prj_semver.get_semver ()

let do_make_meta ~name ~description_file ~target_dir ~depends ~semver ~root_file =
  Prj_project_root.find ~dominating:root_file ()
  >>=? fun project_root ->
  Vrt_common.Dirs.change_to project_root
  >>=? fun () ->
  get_semver semver
  >>=? fun realized_semver ->
  Reader.file_contents description_file
  >>= fun desc ->
  write_meta target_dir name realized_semver desc depends

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-n"] "--name" (required string)
    ~doc:"name The name of the project"
  +> flag ~aliases:["-d"] "--description-file" (required string)
    ~doc:"desc A short description of the project"
  +> flag ~aliases:["-z"] "--target-dir" (required string)
    ~doc:"target-dir The directory in which to generate the opam file"
  +> flag ~aliases:["-p"] "--depends" (listed string)
    ~doc:"depends A runtime dependency of the project"
  +> flag ~aliases:["-s"] "--semver" (optional string)
    ~doc:"depends A runtime dependency of the project"
  +> flag "--root-file" (optional_with_default "Makefile" string)
    ~doc:"root-file The file that identifies the project root. Probably 'Makefile' or 'Vagrantfile'"

let name = "make-meta"

let command =
  Command.async_basic ~summary:"Generates a valid `META` file"
    spec
    (fun name description_file target_dir depends semver root_file () ->
       Vrt_common.Cmd.result_guard
         (fun () -> do_make_meta ~name ~description_file ~target_dir ~depends
             ~semver ~root_file))

let desc = (name, command)
