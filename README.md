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

Developing `vrt`
----------------

Vrt is an opam package. As such it has several dependencies. This can
be found in the 'depends' part of `opam.sh.`.

### Building the opam package

The easiest way to build and test the opam package is to pin the local
repository to opam. Follow the instructions is the
[Opam Pin part of the Opam Packaging docs](http://opam.ocaml.org/doc/Packaging.html).

Once pinned you can install the package as if it where a remote opam
package and everything should just work. The model goes as.

    $> make opam
    $> opam pin add vrt . -n
    $> opam install vrt

That will build and install the system. There can, at times, be
problems if you don't do the `make opam` before the opam pin. Also you
must do `opam remove vrt` before reinstalling.
