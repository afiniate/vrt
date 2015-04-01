open Core.Std
open Core_extended.Std
open Async.Std

exception Cmn_write_error

let write root name contents =
  let path = Filename.implode [root; name] in
  try
    Writer.save path ~contents
    >>| fun _ ->
    Ok ()
  with exn ->
    return @@ Result.Error Cmn_write_error
