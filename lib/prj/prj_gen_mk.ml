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
MLIS:=$(foreach f,$(wildcard $(LIB_DIR)/*.mli),$(notdir $f))

PREFIX := /usr

### Knobs
PARALLEL_JOBS ?= 2
BUILD_FLAGS ?= -use-ocamlfind -cflags -bin-annot -lflags -g

# =============================================================================
# Useful Vars
# =============================================================================

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

.PHONY: all build rebuild metadata install unit-test integ-test test \
        $(TEST_RUN_CMDS)

.PRECIOUS: %/.d

.DEFAULT_GOAL :=

%/.d:
\tmkdir -p $(@D)
\ttouch $@

all: build

rebuild: clean all

build:
\t$(BUILD) $(NAME).cma $(NAME).cmx $(NAME).cmxa $(NAME).a $(NAME).cmxs

metadata:
\tvrt prj make-opam \
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
 --desc $(DESC)

install: metadata
\tcd $(LIB_DIR); ocamlfind install $(NAME) META $(NAME).a $(NAME).cma \
 $(NAME).cmi $(NAME).cmx $(NAME).cmxa $(NAME).cmxs $(MLIS)

remove:
\tocamlfind remove $(NAME)

clean:
\trm -rf $(CLEAN_TARGETS)
\trm -rf $(BUILD_DIR)

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
\t\t--lib $(DEPS) \\
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

let write root filename contents =
  let path = Filename.implode [root; filename] in
  try
    Writer.save path ~contents
    >>| fun _ ->
    Ok ()
  with exn ->
    return @@ Result.Error Gen_mk_write_error

let mk plugins =
   Prj_project_root.find ~dominating:"Makefile" ()
   >>=? fun project_root ->
   write project_root "vrt.mk" makefile
   >>=? fun _ ->
   if List.mem plugins "atdgen" then
     write project_root "myocamlbuild.ml" myocamlbuild
   else
     return @@ Ok ()

let mk_cmd plugins () =
  Common.Cmd.result_guard (fun _ -> mk plugins)

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-p"] "--plugin" (listed string)
    ~doc:"plugin A myocamlbuild plugin (currently only atdgen is supported)."

let name = "gen-mk"

let command =
  Command.async_basic
    ~summary:"Generates `vrt.mk` file in the root of the project directory"
    spec
    mk_cmd

let desc = (name, command)
