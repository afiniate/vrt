open Core.Std
open Core_extended.Std
open Async.Std
open Async_extra.Std

exception Retrieval_failure of String.t

let create_directory_name
  : name:String.t -> semver:String.t -> String.t =
  fun ~name ~semver ->
    name ^ "." ^ semver

let write_opam
  : target_dir:String.t -> license:String.t
  -> maintainer:String.t Option.t -> author:String.t Option.t
  -> homepage:String.t Option.t -> bug_reports:String.t Option.t -> dev_repo:String.t
  -> build_cmds:String.t List.t -> install_cmds:String.t List.t
  -> remove_cmds:String.t List.t -> depends:String.t List.t
  -> build_depends:String.t List.t -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~target_dir ~license ~maintainer
    ~author ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds
    ~remove_cmds ~depends ~build_depends ->
    Opam_make_opam.write_opam ~target_dir ~license ~maintainer
    ~author ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds
    ~remove_cmds ~depends ~build_depends ()

let write_description
  : opam_dir:String.t -> description_file:String.t -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~opam_dir ~description_file ->
    Reader.file_contents description_file
    >>= fun body ->
    Vrt_common.Files.dump ~dir:opam_dir ~name:"descr" ~contents:body

let make_url
  : org:String.t -> name:String.t -> semver:String.t -> Uri.t =
  fun ~org ~name ~semver ->
    let path = "/" ^ org ^ "/" ^ name ^ "/archive/" ^ semver ^ ".tar.gz" in
    Uri.make ~scheme:"https" ~host:"github.com" ~path ()

let rec redirect
  : logger:Log.t -> headers:Cohttp.Header.t -> (String.t, Exn.t) Deferred.Result.t =
  fun ~logger ~headers ->
    match Cohttp.Header.get headers "location" with
    | Some loc ->
      ignore @@ Log.info logger "Got redirected to %s" loc;
      get_uri ~logger ~uri:(Uri.of_string loc)
    | None ->
      return @@ Error (Retrieval_failure "Redirect didn't have location")
and get_uri
  : logger:Log.t -> uri:Uri.t -> (String.t, Exn.t) Deferred.Result.t =
  fun ~logger ~uri ->
    ignore @@ Log.info logger "Retrieving tarbal from %s";
    ignore @@ Vrt_common.Logging.flush logger;
    Cohttp_async.Client.get uri
    >>= function
    | ({Cohttp.Response.status = `OK}, body) ->
      Cohttp_async.Body.to_string body
      >>= fun str_body ->
      return @@ Ok str_body
    | ({Cohttp.Response.status = `Found; headers}, body) ->
      redirect ~logger ~headers
    | (req, _) ->
      return @@ Error (Retrieval_failure (Sexp.to_string @@ Cohttp.Response.sexp_of_t req;))

let format_uri
  : uri:Uri.t -> md5:String.t -> String.t =
  fun ~uri ~md5 ->
    "archive: \"" ^ (Uri.to_string uri) ^ "\"\n" ^
    "checksum: \"" ^ md5 ^ "\""

let write_url
  : logger:Log.t -> target_dir:String.t -> org:String.t -> name:String.t -> semver:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~logger ~target_dir ~org ~name ~semver ->
    let uri = make_url ~org ~name ~semver in
    get_uri ~logger ~uri
    >>=? fun body ->
    let md5 = Digest.string body
              |> Digest.to_hex in
    Vrt_common.Files.dump ~dir:target_dir ~name:"url" ~contents:(format_uri ~uri ~md5)

let do_make_opam_description
  : log_level:Log.Level.t -> org:String.t -> name:String.t
  -> description_file:String.t -> target_dir:String.t
  -> license:String.t -> lib_dir:String.t -> maintainer:String.t Option.t
  -> author:String.t Option.t -> homepage:String.t Option.t
  -> bug_reports:String.t Option.t -> dev_repo:String.t
  -> build_cmds:String.t List.t -> install_cmds:String.t List.t
  -> remove_cmds:String.t List.t -> depends:String.t List.t
  -> build_depends:String.t List.t
  -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~log_level ~org ~name ~description_file ~target_dir ~license
    ~lib_dir ~maintainer ~author ~homepage ~bug_reports
    ~dev_repo ~build_cmds ~install_cmds ~remove_cmds ~depends
    ~build_depends ->
    let logger = Vrt_common.Logging.create log_level in
    Vrt_common.Dirs.change_to target_dir
    >>=? fun _ ->
    ignore @@ Log.info logger "Retrieving semver for project";
    Prj_semver.get_semver ()
    >>=? fun semver ->
    ignore @@ Log.info logger "semver is %s" semver;
    let opam_dir = create_directory_name name semver in
    ignore @@ Log.info logger "creating opam working directory: %s"
      @@ Filename.implode [target_dir; opam_dir];
    Async_shell.mkdir ~p:() opam_dir
    >>= fun _ ->
    ignore @@ Log.info logger "Writing opam file";
    write_opam ~target_dir:opam_dir ~license ~maintainer
      ~author ~homepage ~bug_reports ~dev_repo ~build_cmds ~install_cmds
      ~remove_cmds ~depends ~build_depends
    >>=? fun _ ->
    ignore @@ Log.info logger "Writing opam description";
    write_description ~opam_dir ~description_file
    >>=? fun _ ->
    ignore @@ Log.info logger "Validation url and writing url file";
    let res = write_url ~logger ~target_dir:opam_dir ~org ~name ~semver in
    ignore @@ Log.info logger "Write complete to %s" opam_dir;
    ignore @@ Vrt_common.Logging.flush logger;
    res

let spec =
  let open Command.Spec in
  empty
  +> Vrt_common.Logging.flag
  +> flag ~aliases:["-t"] "--target-dir" (required string)
    ~doc:"target-dir The directory in which to generate the opam file"
  +> flag ~aliases:["-o"] "--organization" (required string)
    ~doc:"organization The name of the github organization/user that owns the product"
  +> flag ~aliases:["-n"] "--name" (required string)
    ~doc:"name The name of the project"
  +> flag ~aliases:["-s"] "--description-file" (required string)
    ~doc:"desc A short description of the project"
  +> flag ~aliases:["-e"] "--license" (required string)
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
    ~doc:"build-command A build command to run during opam build"
  +> flag ~aliases:["-i"] "--install-cmd" (listed string)
    ~doc:"install-command An install command to run during opam install"
  +> flag ~aliases:["-r"] "--remove-cmd" (listed string)
    ~doc:"remove-command A remove command to run during opam remove"
  +> flag ~aliases:["-d"] "--depends" (listed string)
    ~doc:"depends A runtime dependency of the project"
  +> flag ~aliases:["-c"] "--build-depends" (listed string)
    ~doc:"build-depends A build time dependency of the project"

let name = "prepare"

let command: Command.t =
  Command.async_basic ~summary:"Builds the opam directory metadata for a project"
    spec
    (fun log_level target_dir org name description_file license lib_dir
      maintainer author homepage bug_reports dev_repo build_cmds install_cmds
      remove_cmds depends build_depends () ->
      Vrt_common.Cmd.result_guard
        (fun _ -> do_make_opam_description ~log_level ~target_dir ~org ~name
            ~description_file ~license ~lib_dir ~maintainer ~author ~homepage ~bug_reports
            ~dev_repo ~build_cmds ~install_cmds ~remove_cmds ~depends
            ~build_depends))


let desc: String.t * Command.t = (name, command)
