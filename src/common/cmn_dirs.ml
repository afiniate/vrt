open Core.Std
open Async.Std

let gather_dirs root =
  let gatherer acc (name, stats) =
    match stats.Unix.Stats.kind with
    | `Directory ->
      return @@ name::acc
    | _ ->
      return acc in
  let traverser = Async_find.create root in
  Async_find.fold traverser ~init:[root] ~f:gatherer

let gather_all_dirs dirs =
  Deferred.all
  @@ List.map ~f:(fun dir -> gather_dirs dir) dirs
  >>| List.concat

let change_to project_root =
  Unix.chdir project_root
  >>| fun _ ->
  Ok ()
