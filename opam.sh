#!/bin/bash

set -e

ROOT=$1
VRT="$ROOT/_build/lib/vrt.byte"

cat <<EOF

opam-version: "1.2"
name: "vrt"
version: "`$VRT prj semver`"
maintainer: "contact@afiniate.com"
author: "contact@afiniate.com"
homepage: "https://github.com/afiniate/vrt"
bug-reports: "https://github.com/afiniate/vrt/issues"
license: "Apache v2"
dev-repo: "git@github.com:afiniate/vrt.git"

available: [ ocaml-version >= "4.02" ]

build: [
  [make "build"]
]
install: [make "install" "PREFIX=%{prefix}%"]
remove: [make "remove" "PREFIX=%{prefix}%"]
depends: ["ocamlfind" "core" "async" "async_shell" "async_unix" "async_extra"
          "sexplib" "async_shell" "core_extended" "async_find"]

EOF
