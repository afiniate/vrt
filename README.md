Voteraise Commands
==================

Shell scripts are finicky and error prone. Its works much better if we
write our commands in a real language. That real language is ocaml.

`vrt`
-----

The `vrt` command is the entry point for all the tooling in
voteraise. Vrt itself doesn't provide any commands. It consists of
command groups that provide subcommands for the various areas of
tooling. A good example of this is the `build` subcommand group. That
consists of all the tooling related to build and development.


When should I write a Shell script?
-----------------------------------

In a perfect world the answer is never. However, there are times when
it makes sense. The general rule of thumb is to only write shell
scripts for things that must occur before the ocaml project is
buildable. A good example of this is installing the opam library
dependencies.
