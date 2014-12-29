let execvp ~prog ~args () =
  Unix.execvp prog @@ Array.of_list (prog::args)
