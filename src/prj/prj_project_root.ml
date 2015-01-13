open Core.Std
open Core_extended.Std
open Async.Std

type errors =
  | No_project_root_indicator of String.t with sexp

exception Project_root_error of errors with sexp

let find ?(dominating="Makefile") () =
  Sys.getcwd ()
  >>= fun base_dir ->
  Prj_common.search_dominating_file ~base_dir ~dominating ()
  >>| function
  | Some path ->
    Ok (Filename.normalize @@ Filename.make_absolute path)
  | None ->
    Error (Project_root_error (No_project_root_indicator dominating))
