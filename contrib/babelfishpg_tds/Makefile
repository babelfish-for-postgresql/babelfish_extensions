# contrib/babelfishpg_tds/Makefile
MODULE_big = babelfishpg_tds
EXTENSION = babelfishpg_tds
DATA = babelfishpg_tds--1.0.0.sql
PGFILEDESC = "babelfishpg_tds - TDS Listener Extension"

tds_top_dir = .
tds_backend = $(tds_top_dir)/src/backend
tds_include = $(tds_top_dir)/src/include
TSQL_SRC = ../babelfishpg_tsql

export ANTLR4_JAVA_BIN=java
export ANTLR4_RUNTIME_LIB=-lantlr4-runtime
export ANTLR4_RUNTIME_INCLUDE_DIR=/usr/local/include/antlr4-runtime
export ANTLR4_RUNTIME_LIB_DIR=/usr/local/lib

PG_CFLAGS += -Werror -Wfloat-conversion
PG_CFLAGS += -fstack-protector-strong
PG_CXXFLAGS += -I$(ANTLR4_RUNTIME_INCLUDE_DIR)
PG_CXXFLAGS += -Wno-deprecated -Wno-error=attributes -Wno-suggest-attribute=format # disable some warnings from ANTLR runtime header
PG_CPPFLAGS += -I$(TSQL_SRC)  -I$(TSQL_SRC)/src -I$(PG_SRC) -I$(tds_top_dir) -DFAULT_INJECTOR

SHLIB_LINK += -L$(ANTLR4_RUNTIME_LIB_DIR) $(ANTLR4_RUNTIME_LIB)

# Exclude the following files from the build (sometimes these
# files are included in another c file)
tds_exclude_files = $(tds_backend)/tds/support_funcs.c \
					$(tds_backend)/tds/tds_data_map.c \
					$(tds_backend)/tds/tdsprinttup.c

tds_temp_srcs = $(shell find $(tds_top_dir) -name "*.c")
tds_srcs = $(filter-out $(tds_exclude_files), $(tds_temp_srcs))

OBJS = $(patsubst %.c, %.o, $(tds_srcs))
OBJS +=$(TSQL_SRC)/src/tsqlwarmup.o
OBJS += $(TSQL_SRC)/antlr/libantlr_tsql.a

$(TSQL_SRC)/antlr/Makefile: $(TSQL_SRC)/antlr/CMakeLists.txt $(TSQL_SRC)/antlr/TSqlLexer.g4 $(TSQL_SRC)/antlr/TSqlLexer.g4
	cd $(TSQL_SRC)/antlr && $(cmake) . && cd $(tds_top_dir)

.PHONY: $(TSQL_SRC)/antlr/libantlr_tsql.a  # to allow CMake's make check the build
$(TSQL_SRC)/antlr/libantlr_tsql.a: $(TSQL_SRC)/antlr/Makefile
	$(MAKE) -C $(@D) all

$(TSQL_SRC)/src/tsqlwarmup.o: $(TSQL_SRC)/src/tsqlwarmup.cpp

$(tds_include)/error_mapping.h: error_mapping.txt generate_error_mapping.pl
	$(PERL) generate_error_mapping.pl $< > $@
$(tds_backend)/tds/err_handler.o: $(tds_include)/error_mapping.h

# Disable for now
#NO_PGXS = 1

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Only execute TAP tests if sqlcmd is installed in the path
ifneq (, $(shell which sqlcmd))
SUBDIRS = test
endif

#include ../Makefile.common

.DEFAULT_GOAL := all

$(recurse)
$(recurs_always)
