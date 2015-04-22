open Core.Std
open Core_extended.Std
open Async.Std

let dump
  : dir:String.t -> name:String.t -> contents:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~dir ~name ~contents ->
    let path = Filename.implode [dir; name] in
    try
      Writer.save path ~contents
      >>| fun _ ->
      Ok ()
    with exn ->
      return @@ Error exn
