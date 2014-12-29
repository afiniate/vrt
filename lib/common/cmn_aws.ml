open Core.Std
open Core_extended.Std
open Async.Std

type errors =
  | Unable_to_find_region
  | Invalid_identity with sexp

exception Aws_error of errors with sexp

let region () =
  (Async_shell.sh_one "grep region ~/.aws/config | awk -F\" \" '{print $3}'")
  >>= function
  | Some region -> return @@ Ok region
  | None -> return @@ Error (Aws_error Unable_to_find_region)

let merge home user =
  region ()
  >>=? fun reg ->
  let region_mapped_pem = Filename.implode [home; ".ssh"; user ^ "." ^ reg ^ ".pem"] in
  let direct_pem = Filename.implode [home; ".ssh"; user ^ ".pem"] in
  Sys.file_exists region_mapped_pem
  >>| function
  | `Yes ->
    Ok region_mapped_pem
  | _ ->
    Ok direct_pem

let get_env_elements () =
  let open Option.Monad_infix in
  Sys.getenv "HOME"
  >>= fun home ->
  Cmn_afiniate.user
  >>| fun user ->
  (home, user)

let identity () =
  match get_env_elements () with
  | Some (home, user) ->
    merge home user
  | None ->
    return @@ Error (Aws_error Invalid_identity)
