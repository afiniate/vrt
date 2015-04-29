NAME:=vrt
LICENSE:="OSI Approved :: Apache Software License v2.0"
AUTHOR:="Afiniate, Inc."
ORGANIZATION:="afiniate"
HOMEPAGE:="https://github.com/afiniate/vrt"

DEV_REPO:="git@github.com:afiniate/vrt.git"
BUG_REPORTS:="https://github.com/afiniate/vrt/issues"

BUILD_DEPS:=core async async_unix async_extra sexplib.syntax sexplib \
	async_shell core_extended async_find trv

DEPS:=$(BUILD_DEPS)

DESC_FILE := $(CURDIR)/descr

EXTRA_TARGETS := vrt.native

install-extra:
	cp $(BUILD_DIR)/lib/trv.native $(PREFIX)/bin/trv

trv.mk:
	trv build gen-mk

-include trv.mk
