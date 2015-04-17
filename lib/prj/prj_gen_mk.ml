open Core.Std
open Core_extended.Std
open Async.Std

exception Gen_mk_write_error

(* Contents of the generic .mk generated file *)

let makefile = "# You can control some aspects of the build with next variables (e.g.
# make VARIABLE_NAME=\"some-value\")
#
# * PARALLEL_JOBS=N let ocamlbuild run N jobs in parallel. The recommended
# value is the number of cores of your machine. Note that we don't want to
# use make's own parallel flag (-j), as it will spawn several ocamlbuild jobs
# competing with each other
# * BUILD_FLAGS flags used to compile non production ocaml code (e.g tools,
# tests ...)
# * BUILD_PROD_FLAGS flags used to compile production ocaml code
#
# =============================================================================
# VARS
# =============================================================================
BUILD_DIR := $(CURDIR)/_build
SOURCE_DIR := lib
LIB_DIR := $(BUILD_DIR)/$(SOURCE_DIR)

PREFIX := /usr

### Knobs
PARALLEL_JOBS ?= 2
BUILD_FLAGS ?= -use-ocamlfind -cflags -bin-annot -lflags -g

# =============================================================================
# Useful Vars
# =============================================================================
SEMVER := $(shell vrt prj semver)
BUILD := ocamlbuild -j $(PARALLEL_JOBS) -build-dir $(BUILD_DIR) $(BUILD_FLAGS)

MOD_DEPS=$(foreach DEP,$(DEPS), --depends $(DEP))
BUILD_MOD_DEPS=$(foreach DEP,$(BUILD_DEPS), --build-depends $(DEP))

UTOP_MODS=$(foreach DEP,$(DEPS),\\#require \\\"$(DEP)\\\";;)

UTOP_INIT=$(BUILD_DIR)/init.ml

### Test bits
TESTS_DIR := $(BUILD_DIR)/tests
TEST_RUN_SRCS := $(shell find $(SOURCE_DIR) -name \"*_tests_run.ml\")
TEST_RUN_EXES := $(notdir $(TEST_RUN_SRCS:%.ml=%))
TEST_RUN_CMDS := $(addprefix $(TESTS_DIR)/, $(TEST_RUN_EXES))
TEST_RUN_TARGETS:= $(addprefix run-, $(TEST_RUN_EXES))

# =============================================================================
# Rules to build the system
# =============================================================================

.PHONY: all build rebuild metadata prepare submit install unit-test \
        integ-test test remove clean \
        opam unpin-repo pin-repo install-local-opam \
        install-library install-extra \
        $(TEST_RUN_CMDS)

.PRECIOUS: %/.d

.DEFAULT_GOAL :=

%/.d:
\tmkdir -p $(@D)
\ttouch $@

all: build

rebuild: clean all

build:
\t$(BUILD) $(NAME).cma $(NAME).cmx $(NAME).cmxa $(NAME).a $(NAME).cmxs $(EXTRA_TARGETS)

metadata:
\tvrt prj make-meta \
 --name $(NAME) \
 --target-dir $(LIB_DIR) \
 --root-file vrt.mk \
 --semver $(SEMVER) \
 --description-file '$(DESC_FILE)' \
 $(MOD_DEPS)

# This is only used to help during local opam package
# development
opam: build
\tvrt opam make-opam \
 --target-dir $(CURDIR) \
 --name $(NAME) \
 --semver $(SEMVER) \
 --homepage $(HOMEPAGE) \
 --dev-repo $(DEV_REPO) \
 --lib-dir $(LIB_DIR) \
 --license $(LICENSE) \
 --author $(AUTHOR) \
 --maintainer $(AUTHOR) \
 --bug-reports $(BUG_REPORTS) \
 --build-cmd \"make\" \
 --install-cmd 'make \"install\" \"PREFIX=%{prefix}%\" \"SEMVER=%{aws_async:version}%\"' \
 --remove-cmd 'make \"remove\" \"PREFIX=%{prefix}%\"' \
 $(BUILD_MOD_DEPS) $(MOD_DEPS) \


unpin-repo:
\topam pin remove -y $(NAME)

pin-repo:
\topam pin add -y $(NAME) $(CURDIR)

install-local-opam: opam pin-repo
\topam remove $(NAME); \
 opam install $(NAME)

prepare: build
\tvrt opam prepare \
 --organization $(ORGANIZATION) \
 --target-dir $(BUILD_DIR) \
 --homepage $(HOMEPAGE) \
 --dev-repo $(DEV_REPO) \
 --lib-dir $(LIB_DIR) \
 --license $(LICENSE) \
 --name $(NAME) \
 --author $(AUTHOR) \
 --maintainer $(AUTHOR) \
 --bug-reports $(BUG_REPORTS) \
 --build-cmd \"make\" \
 --install-cmd 'make \"install\" \"PREFIX=%{prefix}%\"' \
 --remove-cmd 'make \"remove\" \"PREFIX=%{prefix}%\"' \
 $(BUILD_MOD_DEPS) $(MOD_DEPS) \
 --description-file '$(DESC_FILE)'

install-library: metadata
\tcd $(LIB_DIR); ocamlfind install $(NAME) META \
 `find ./  -name \"*.cmi\" -o -name \"*.cmo\" \
  -o -name \"*.o\" -o -name \"*.cmx\" -o -name \"*.cmxa\" \
  -o -name \"*.cmxs\" -o -name \"*.a\" \
  -o -name \"*.cma\"`

install: install-library install-extra

submit: prepare
\topam-publish submit $(BUILD_DIR)/$(NAME).$(SEMVER)

remove:
\tocamlfind remove $(NAME)

clean:
\trm -rf $(CLEAN_TARGETS)
\trm -rf $(BUILD_DIR)
\trm -rf vrt.mk


# =============================================================================
# Rules for testing
# =============================================================================

compile-tests: $(TEST_RUN_CMDS)

$(TEST_RUN_CMDS): $(TESTS_DIR)/.d
\t$(BUILD) $(notdir $@).byte
\t@find $(LIB_DIR) -name $(notdir $@).byte -exec cp {} $(@) \\;

$(TEST_RUN_TARGETS): run-%: $(TESTS_DIR)/%
\t$<

test: build unit-test integ-test

unit-test: $(filter %_unit_tests_run, $(TEST_RUN_TARGETS))

integ-test: $(filter %_integ_tests_run, $(TEST_RUN_TARGETS))


# =============================================================================
# Support
# =============================================================================
$(UTOP_INIT): build
\t@echo \"$(UTOP_MODS)\" > $(UTOP_INIT)
\t@echo \"open Core.Std;;\" >> $(UTOP_INIT)
\t@echo \"open Async.Std;;\" >> $(UTOP_INIT)
\t@echo '#load \"$(NAME).cma\";;' >> $(UTOP_INIT)

utop: $(UTOP_INIT)
\tutop -I $(LIB_DIR) -init $(UTOP_INIT)

.merlin: build
\tvrt prj make-dot-merlin \\
\t\t--build-dir $(BUILD_DIR) \\
\t\t--lib \"$(DEPS)\" \\
\t\t--source-dir $(SOURCE_DIR)
"


(* Contents of the myocamlbuild generated file *)

let myocamlbuild = "
open Ocamlbuild_plugin;;

Options.use_ocamlfind := true;;

module Atdgen = struct
  let cmd = \"atdgen\" (* TODO detect from ./configure phase *)
  let run_atdgen dst tagger env _ =
    let tags = tagger (tags_of_pathname (env dst) ++\"atdgen\") in
    let dir = Filename.dirname (env dst) in
    let fname = Filename.basename (env \"%.atd\") in
    Cmd (S [A \"cd\"; Px dir; Sh \"&&\"; A cmd; T tags; Px fname])

  let rules () =
    rule \"%.atd -> %.ml{i}\" ~prods:[\"%.ml\";\"%.mli\"] ~dep:\"%.atd\"
      (run_atdgen \"%.ml\" (fun tags -> tags++\"generate\"++\"std_json\"));
    rule \"%.atd -> %_j.ml{i}\" ~prods:[\"%_j.ml\";\"%_j.mli\"] ~dep:\"%.atd\"
      (run_atdgen \"%_j.ml\" (fun tags -> tags++\"generate\"++\"std_json\"));
    rule \"%.atd -> %_t.ml{i}\" ~prods:[\"%_t.ml\";\"%_t.mli\"] ~dep:\"%.atd\"
      (run_atdgen \"%_t.ml\" (fun tags -> tags++\"generate\"++\"typedef\"));
    rule \"%.atd -> %_b.ml{i}\" ~prods:[\"%_b.ml\";\"%_b.mli\"] ~dep:\"%.atd\"
      (run_atdgen \"%_b.ml\" (fun tags -> tags++\"generate\"++\"biniou\"));
    rule \"%.atd -> %_v.ml{i}\" ~prods:[\"%_v.ml\";\"%_v.mli\"] ~dep:\"%.atd\"
      (run_atdgen \"%_v.ml\" (fun tags -> tags++\"generate\"++\"validator\"));
    flag [\"atdgen\"; \"generate\"; \"json\"] & S[A\"-j\"];
    flag [\"atdgen\"; \"generate\"; \"std_json\"] & S[A\"-j\"; A\"-j-std\"];
    flag [\"atdgen\"; \"generate\"; \"typedef\"] & S[A\"-t\"];
    flag [\"atdgen\"; \"generate\"; \"biniou\"] & S[A\"-b\"];
    flag [\"atdgen\"; \"generate\"; \"validator\"] & S[A\"-v\"];
end;;

dispatch begin function
 | After_rules ->
   Atdgen.rules ()
 | _ -> ()
end"

let write logger root filename contents =
  let path = Filename.implode [root; filename] in
  Log.info logger "Writing makefile to %s" path;
  try
    Writer.save path ~contents
    >>| fun _ ->
    Ok ()
  with exn ->
    return @@ Result.Error Gen_mk_write_error

let mk ~log_level ~plugins =
  let logger = Vrt_common.Logging.create log_level in
  Prj_project_root.find ~dominating:"Makefile" ()
  >>=? fun project_root ->
  write logger project_root "vrt.mk" makefile
  >>=? fun _ ->
  if List.mem plugins "atdgen" then
    write logger project_root "myocamlbuild.ml" myocamlbuild
    >>= fun result ->
    ignore @@ Vrt_common.Logging.flush logger;
    return result
  else
    return @@ Ok ()

let spec =
  let open Command.Spec in
  empty
  +> Vrt_common.Logging.flag
  +> flag ~aliases:["-p"] "--plugin" (listed string)
    ~doc:"plugin A myocamlbuild plugin (currently only atdgen is supported)."

let name = "gen-mk"

let command =
  Command.async_basic
    ~summary:"Generates `vrt.mk` file in the root of the project directory"
    spec
    (fun log_level plugins () ->
       Vrt_common.Cmd.result_guard (fun _ -> mk ~log_level ~plugins))



let desc = (name, command)
