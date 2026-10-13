# 00-hello-world: Standard Terminal Hello World, in Objective-C.
#
# The universal build contract (shared/templates/BASE-MAKEFILE) defines the standard targets:
#
#   make all | install | uninstall | test | check | lint | format | clean | distclean
#   make test-hidden | grade | help
#
# The hooks below compile src/DPHello/ with the platform's Objective-C compiler and Foundation
# (GCC + GNUstep Base in the container and on Linux, Apple Clang + Foundation on macOS, Clang +
# libobjc2 + GNUstep Base in MSYS2 CLANG64 on Windows), run the plain-assertion unit tests in
# src/Tests/, and check formatting with clang-format 19 (style: ../.clang-format).
# Container-first: goals run in the toolchain container built from ../Containerfile
# (podman, then docker, then local; override with DP_RUNTIME). DP_RUNTIME=local builds natively.

PROJECT := 00-hello-world
TOOLS   := dp-hello

# Path to the sdlc-curriculum checkout (the specs, test suites, and runner live there).
CURRICULUM_ROOT ?= ../sdlc-curriculum

# The compiler and Foundation flags per OS, as in the root Makefile's toolchain probe.
# (GNU Make 3.82+ predefines OBJC=cc; only a default or missing value is replaced.)
ifeq ($(shell uname -s),Darwin)
  OBJC_DEFAULT := clang
  OBJC_CFLAGS ?= -x objective-c
  OBJC_LIBS ?= -framework Foundation
else
  OBJC_DEFAULT := $(if $(filter Windows_NT,$(OS)),clang,gcc)
  OBJC_CFLAGS ?= $$(gnustep-config --objc-flags)
  OBJC_LIBS ?= $$(gnustep-config --base-libs)
endif
ifneq ($(filter default undefined,$(origin OBJC)),)
  OBJC := $(OBJC_DEFAULT)
endif
CLANG_FORMAT ?= clang-format

BUILD_DIR := build
BIN_DIR   := $(BUILD_DIR)/bin

APP_SOURCES  := $(wildcard src/DPHello/*.m)
LIB_SOURCES  := $(filter-out src/DPHello/main.m,$(APP_SOURCES))
TEST_SOURCES := $(wildcard src/Tests/*.m)
FORMAT_FILES := $(wildcard src/DPHello/*.[hm] src/Tests/*.[hm])

# Manual reference counting (no ARC: GCC has none), so the code is the same for every compiler.
WARNINGS := -Wall
DP_OBJCFLAGS = $(OBJC_CFLAGS) -std=gnu11 $(WARNINGS) -Isrc/DPHello -O2
# Windows: enter through wmain to receive the UTF-16 command line (see src/DPHello/main.m).
APP_LDFLAGS := $(if $(filter Windows_NT,$(OS)),-municode)

UNIT_TESTS := $(BUILD_DIR)/tests/unit-tests$(EXE)

# $(call compile,FLAGS,OUTPUT,SOURCES,LDFLAGS): one compile-and-link step. GNUstep's flags
# include -MMD, so each output directory also receives dependency (.d) files.
compile = $(OBJC) $(DP_OBJCFLAGS) $(1) -o $(2) $(3) $(OBJC_LIBS) $(LDFLAGS) $(4)

define DP_BUILD
@mkdir -p $(BIN_DIR)
$(call compile,,$(BIN_DIR)/dp-hello$(EXE),$(APP_SOURCES),$(APP_LDFLAGS))
endef

define DP_INSTALL
mkdir -p "$(BINDIR)"
cp $(BIN_DIR)/dp-hello$(EXE) "$(BINDIR)/dp-hello$(EXE)"
endef

define DP_UNINSTALL
rm -f "$(BINDIR)/dp-hello$(EXE)"
endef

define DP_UNIT_TEST
@mkdir -p $(BUILD_DIR)/tests
$(call compile,,$(UNIT_TESTS),$(LIB_SOURCES) $(TEST_SOURCES))
$(UNIT_TESTS)
endef

# Lint: every source must compile without a single warning, and match the clang-format style.
define DP_LINT
@mkdir -p $(BUILD_DIR)/lint
$(call compile,-Werror,$(BUILD_DIR)/lint/dp-hello$(EXE),$(APP_SOURCES),$(APP_LDFLAGS))
$(call compile,-Werror,$(BUILD_DIR)/lint/unit-tests$(EXE),$(LIB_SOURCES) $(TEST_SOURCES))
$(CLANG_FORMAT) --dry-run --Werror $(FORMAT_FILES)
endef

define DP_FORMAT
$(CLANG_FORMAT) -i $(FORMAT_FILES)
endef

define DP_CLEAN
rm -rf $(BUILD_DIR) *.d
endef

# Nothing else is cached in the project directory: no dependencies, no generated config.
define DP_DISTCLEAN
rm -rf $(BUILD_DIR)
endef

include $(CURRICULUM_ROOT)/shared/templates/BASE-MAKEFILE
