open Core.Std
open Core_extended.Std
open Async.Std

let opam_string_of_command_list
  : String.t List.t -> String.t =
  fun cmds ->  "[\n" ^
               (List.fold ~init:""
                  ~f:(fun acc el -> acc ^ "    [" ^ el ^ "]\n") cmds) ^
               "]\n"
let format_cmds
  : default:String.t List.t -> String.t List.t -> String.t =
  fun ~default cmds ->
    match cmds with
    | [] -> opam_string_of_command_list default
    | _ -> opam_string_of_command_list cmds

let create_build_cmds
  : String.t List.t -> String.t =
  format_cmds ~default:["make build"]

let create_install_cmds
  : String.t List.t -> String.t =
  format_cmds ~default:["make install"]

let create_remove_cmds
  : String.t List.t -> String.t =
  format_cmds ~default:["make remove"]

let format_dependencies
  : ?annotation:String.t -> String.t List.t -> String.t =
  fun ?(annotation="") ->
    List.fold ~init:""
      ~f:(fun acc el -> acc ^ " \"" ^ el ^ "\" " ^ annotation)

let format_build_dependencies
  : String.t List.t -> String.t =
  format_dependencies ~annotation:"{build}"

let make_optional_field
  : name:String.t -> String.t Option.t -> String.t =
  fun ~name value ->
    match value with
    | Some m -> name ^ ": \"" ^ m ^ "\"\n"
    | None -> ""

let write_opam
  : target_dir:String.t -> name:String.t -> semver:String.t
  -> license:String.t -> maintainer:String.t Option.t -> author:String.t Option.t
  -> homepage:String.t Option.t -> bug_reports:String.t Option.t -> dev_repo:String.t
  -> build_cmds:String.t List.t -> install_cmds:String.t List.t
  -> remove_cmds:String.t List.t -> depends:String.t List.t
  -> build_depends:String.t List.t -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~target_dir ~name ~semver ~license ~maintainer
    ~author ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds
    ~remove_cmds ~depends ~build_depends ->
    let maintainer_str = make_optional_field ~name:"maintainer" maintainer in
    let author_str = make_optional_field ~name:"author" author in
    let homepage_str = make_optional_field ~name:"homepage" homepage in
    let bug_str = make_optional_field ~name:"bug-reports" bug_reports in
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
                   "build: " ^ (create_build_cmds build_cmds) ^ "\n" ^
                   "install: " ^ (create_install_cmds install_cmds) ^ "\n" ^
                   "remove: " ^ (create_remove_cmds remove_cmds) ^ "\n" ^
                   "\n" ^
                   "depends: [" ^ ((format_build_dependencies build_depends) ^
                                   (format_dependencies depends)) ^ "]\n" in
    Afin.Files.dump ~dir:target_dir ~name:"opam" ~contents

let get_target_dir
  : target_dir: String.t Option.t -> root_file:String.t ->
  (String.t, Exn.t) Deferred.Result.t =
  fun ~target_dir ~root_file ->
    match target_dir with
    | Some dir ->
      return @@ Ok dir
    | None ->
      Prj_project_root.find ~dominating:root_file ()

let do_make_opam
  : name:String.t -> target_dir:String.t Option.t
  -> license:String.t -> lib_dir:String.t -> maintainer:String.t Option.t
  -> author:String.t Option.t -> homepage:String.t Option.t
  -> bug_reports:String.t Option.t -> dev_repo:String.t
  -> build_cmds:String.t List.t -> install_cmds:String.t List.t
  -> remove_cmds:String.t List.t -> depends:String.t List.t
  -> build_depends:String.t List.t -> root_file:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~name ~target_dir ~license ~lib_dir ~maintainer ~author
    ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds ~remove_cmds
    ~depends ~build_depends ~root_file ->
  get_target_dir ~target_dir ~root_file
  >>=? fun opam_root ->
  Common.Dirs.change_to opam_root
  >>=? fun _ ->
  Prj_semver.get_semver ()
  >>=? fun semver ->
  write_opam ~target_dir:opam_root ~name ~semver ~license ~maintainer ~author
      ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds ~remove_cmds
      ~depends ~build_depends

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-n"] "--name" (required string)
    ~doc:"name The name of the project"
  +> flag ~aliases:["-t"] "--target-dir" (optional string)
    ~doc:"target-dir The directory in which to generate the opam file"
  +> flag ~aliases:["-l"] "--license" (required string)
    ~doc:"license The license for this project"
  +> flag ~aliases:["-z"] "--lib-dir" (required string)
    ~doc:"lib-dir The main library dir for the project - For the META file"
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
  +> flag "--root-file" (optional_with_default "Makefile" string)
    ~doc:"root-file The file that identifies the project root. Probably 'Makefile' or 'Vagrantfile'"

let name = "make-opam"

let command: Command.t =
  Command.async_basic ~summary:"Generates a valid `opam` and `META` filey"
    spec
    (fun name target_dir license lib_dir maintainer author
      homepage bug_reports dev_repo build_cmds install_cmds remove_cmds depends
      build_depends root_file () ->
      Common.Cmd.result_guard
        (fun _ -> do_make_opam ~name ~target_dir ~license ~lib_dir
            ~maintainer ~author ~homepage ~bug_reports ~dev_repo ~build_cmds
            ~install_cmds ~remove_cmds ~depends ~build_depends ~root_file))


let desc: String.t * Command.t = (name, command)
