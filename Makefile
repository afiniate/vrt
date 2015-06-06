NAME:=vrt
LICENSE:="OSI Approved :: Apache Software License v2.0"
AUTHOR:="Afiniate, Inc."
ORGANIZATION:="afiniate"
HOMEPAGE:="https://github.com/afiniate/vrt"

DEV_REPO:="git@github.com:afiniate/vrt.git"
BUG_REPORTS:="https://github.com/afiniate/vrt/issues"

OCAML_DEPS ?= core async core_extended uri cohttp \
      async_shell async_find

OCAML_FIND_DEPS ?= cohttp.async

OCAML_PKG_DEPS ?= ocaml findlib camlp4

DEPS ?= git trv

DESC_FILE := $(CURDIR)/descr

EXTRA_TARGETS := vrt.native

install-extra:
	cp $(BUILD_DIR)/lib/vrt.native $(PREFIX)/bin/vrt

trv.mk:
	trv build gen-mk

-include trv.mk
