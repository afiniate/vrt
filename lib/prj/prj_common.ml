open Core.Std
open Core_extended.Std
open Async.Std
open Deferred.Monad_infix

let rec search_dominating_file' dominating = function
  | [] ->
    return None
  | h::t ->
    let path = Filename.implode @@ List.rev (dominating::t) in
    Sys.file_exists path
    >>= (function
        | `Yes -> return @@ Some (Filename.implode @@ List.rev t)
        | `No -> search_dominating_file' dominating t
        | `Unknown -> search_dominating_file' dominating t)

let search_dominating_file ~base_dir ~dominating () =
  let element_list = List.rev @@ Filename.explode base_dir in
  search_dominating_file' dominating element_list
