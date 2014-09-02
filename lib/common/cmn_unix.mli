open Core.Std

(** Provides wrappers and helps for common unix system interaction *)

val execvp: prog:String.t -> args:String.t List.t -> Unit.t -> Unit.t
(** execv prog args execute the program in file prog, with the
    arguments args, and the current process environment. These execvp
    function never return: on success, the current program is replaced by
    the new one; on failure, a UnixLabels.Unix_error exception is
    raised.
*)
