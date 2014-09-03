open Core.Std
open Async.Std

let guard fn =
  Monitor.try_with
    fn
  >>| function
  | Ok _ ->
    shutdown 0
  | Error monitor_exn ->
    (match Monitor.extract_exn monitor_exn with
     | Async_shell.Process.Failed result ->
       if not (result.stdout = "")
       then print_string result.stdout
       else ();
       if not (result.stderr = "")
       then print_string result.stderr
       else ()
     | new_exn ->
       raise new_exn);
    shutdown 1

let result_guard def_fn =
  guard (fun () ->
      def_fn ()
      >>= function
      | Ok _ ->
        return ()
      | Error exn ->
        raise exn)
