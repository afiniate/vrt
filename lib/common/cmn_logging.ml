open Core.Std
open Async.Std

let log_level =
  Command.Spec.Arg_type.create
    (function
      | "v" -> `Error
      | "vv" -> `Info
      | "vvv" -> `Debug
      | "error" -> `Error
      | "info" -> `Info
      | "debug" -> `Debug
      | _ -> `Debug)

let flag =
  Command.Spec.(flag ~aliases:["-l"] "--log-level" (optional_with_default `Info log_level)
                  ~doc:"log-level The log level to set")

let create log_level =
  Log.create log_level [Log.Output.stdout ()]

let flush logger =
  Log.flushed logger
  >>| fun _ ->
  Ok ()
