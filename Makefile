# Copyright 2013 Afiniate All Rights Reserved.
#
# You can control some aspects of the build with next variables (e.g.
# make VARIABLE_NAME="some-value")
#
#  * PARALLEL_JOBS=N let ocamlbuild run N jobs in parallel. The recommended
#    value is the number of cores of your machine. Note that we don't want to
#    use make's own parallel flag (-j), as it will spawn several ocamlbuild jobs
#    competing with each other
#  * BUILD_FLAGS flags used to compile non production ocaml code (e.g tools,
#    tests ...)
#  * BUILD_PROD_FLAGS flags used to compile production ocaml code
#
# =============================================================================
# VARS
# =============================================================================
BUILD_DIR := $(CURDIR)/_build

PREFIX := /usr

### Knobs
PARALLEL_JOBS ?= 2
BUILD_FLAGS ?= -use-ocamlfind -cflags -bin-annot -lflags -g

# =============================================================================
# COMMANDS
# =============================================================================

OCAML_CMD := ocaml
OCAML := $(shell which $(OCAML_CMD))

OCC_CMD := ocamlbuild
OCC := $(shell which $(OCC_CMD)) -j $(PARALLEL_JOBS)

BUILD := $(OCC) -build-dir $(BUILD_DIR) $(BUILD_FLAGS)

# =============================================================================
# Rules to build the system
# =============================================================================

.PHONY: all build rebuild opam install

.PRECIOUS: %/.d

%/.d:
	mkdir -p $(@D)
	touch $@

all: build

rebuild: clean all

build:
	$(BUILD) vrt.native vrt.byte

opam:
	$(CURDIR)/opam.sh $(CURDIR) > opam

install:
	cp $(BUILD_DIR)/src/vrt.native $(PREFIX)/bin/vrt

remove:
	rm $(PREFIX)/bin/vrt

clean:
	rm $(CURDIR)/opam
	rm -rf $(BUILD_DIR)
