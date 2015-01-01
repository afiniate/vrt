open Core.Std
open Async.Std
open Re2.Std

exception Semver_commit_count_failure of String.t
exception Semver_version_parse_failure of String.t
exception Semver_git_describe_parse_failure of String.t

let create_with_commit_count ref =
  Async_shell.sh_one
    "git rev-list HEAD --count"
  >>| function
  | Some count ->
    Ok ("0.0.0" ^ "+build." ^ count ^ "." ^ ref)
  | None ->
    Error (Semver_commit_count_failure"nothing")

let deep_parse potential_ver =
  return (let open Or_error.Monad_infix in
          Re2.create "^((v)?(\\d+(\\.\\d+(\\.\\d+)?)))$|^([A-Fa-f0-9]+)$"
          >>= fun re ->
          Re2.find_submatches re potential_ver)

let parse_ver potential_ver top =
  deep_parse potential_ver
  >>= function
  | Ok [|Some _; _; _; _; _; _; Some ref|] ->
    if top
    then create_with_commit_count ref
    else return @@ Ok ref

  | Ok [|Some _; _; _; Some ver; _; _; _|] ->
    return @@ Ok ver
  | _ ->
    return @@ Error (Semver_version_parse_failure potential_ver)

let split_version = function
  | Some ver ->
    return (let open Or_error.Monad_infix in
            Re2.create "-"
            >>| fun re ->
            Re2.split re ver)
  | _ ->
    return @@ Or_error.error_string "No version returned"

let parse ver =
  split_version ver
  >>= function
  | Ok [ver] ->
    parse_ver ver true
  | Ok [ver; count; gitref] ->
    parse_ver ver false
    >>|? fun ver ->
    ver ^ "+build." ^ count ^ "." ^ gitref
  | _ ->
    (match ver with
     | Some ver ->
       return @@ Error (Semver_git_describe_parse_failure ver)
     | None ->
       return @@ Error (Semver_git_describe_parse_failure "none"))

let get_semver () =
  Async_shell.sh_one "git describe --tags --always"
  >>= fun str_opt ->
  parse str_opt

let do_semver () =
  get_semver ()
  >>|? fun result ->
  print_string result;
  Ok ()

let monitor_semver () =
  Common.Cmd.result_guard
    (fun _ -> do_semver ())

let spec =
  let open Command.Spec in
  empty

let name = "semver"

let command =
  Command.async_basic ~summary:"Parse git repo information into a semantic version"
    spec
    monitor_semver

let desc = (name, command)
