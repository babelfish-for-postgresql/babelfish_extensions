# Note: this Makefile uses pg_config to find various header
#       files and built tools.
include Version.config

EXTENSION = babelfishpg_tsql
EXTVERSION = $(PGTSQL_MAJOR_VERSION).$(PGTSQL_MINOR_VERSION).$(PGTSQL_MICRO_VERSION)

#subdir = contrib/babelfishpg_tsql

# Note:
#	Set PREV_EXTVERSION after release, i.e after release of 3.0.0, set PREV_EXTVERSION to 3.0.0
#	babel_upgrade test target should at the top of the src/test/regress/babel_schedule
# 	src/test/regress/sql/babel_upgrade.sql should be modified to include the PREV_EXTVERSION to test the upgrade path
# 	contrib/babelfishpg_tsql/sql/upgrades/$(EXTENSION)--$(PREV_EXTVERSION).sql should be present to test the upgrade path
PREV_EXTVERSION = 1.0.0
MODULEPATH = $$libdir/$(EXTENSION)-$(PGTSQL_MAJOR_VERSION)
MODULE_big = $(EXTENSION)

# $(OBJS) should contain the name of each .o file that
#         we link into the extension
OBJS = src/pl_gram.o src/pl_handler.o src/pl_comp.o src/pl_exec.o
OBJS += src/pl_funcs.o src/pl_scanner.o $(WIN32RES)
OBJS += src/pl_comp-2.o
OBJS += src/pl_explain.o
OBJS += src/properties.o
OBJS += src/databasepropertyex.o
OBJS += src/plan_inval.o
OBJS += src/procedures.o
OBJS += src/cursor.o
OBJS += src/applock.o
OBJS += src/pltsql_coerce.o
OBJS += runtime/functions.o
OBJS += src/err_handler.o
OBJS += src/pltsql_function_probin_handler.o
OBJS += src/pltsql_utils.o
OBJS += src/tablecmds.o
OBJS += src/stmt_walker.o
OBJS += src/codegen.o
OBJS += src/dynavec.o
OBJS += src/dynastack.o
OBJS += src/analyzer.o
OBJS += src/prepare.o
OBJS += src/compile_context.o
OBJS += src/collation.o src/string.o src/format.o
OBJS += src/pltsql_identity.o
OBJS += src/collationproperty.o
OBJS += src/rolecmds.o
OBJS += src/backend_parser/keywords.o
OBJS += src/backend_parser/parser.o
OBJS += src/backend_parser/scan-backend.o
OBJS += src/backend_parser/gram-backend.o
OBJS += src/backend_parser/gram_hook.o
OBJS += src/dbcmds.o
OBJS += src/session.o
OBJS += src/guc.o
OBJS += src/catalog.o
OBJS += src/schemacmds.o
OBJS += src/hooks.o
OBJS += src/tsqlNodes.o
OBJS += src/tsqlHandler.o
OBJS += src/tsqlUnsupportedFeatureHandler.o
OBJS += src/tsqlIface.o
OBJS += src/special_keywords.o
OBJS += antlr/libantlr_tsql.a
OBJS += src/multidb.o
OBJS += src/json_funcs.o
OBJS += src/pltsql_ruleutils.o
OBJS += src/tsql_for/tsql_for.o
OBJS += src/tsql_for/forjson.o
OBJS += src/tsql_for/forjson_old.o
OBJS += src/tsql_for/forxml.o
OBJS += src/tsql_for/forxml_old.o
OBJS += src/tsql_analyze.o
OBJS += src/linked_servers.o
OBJS += src/table_variable_mvcc.o
OBJS += src/extendedproperty.o
OBJS += src/fts.o
OBJS += src/fts_parser.o
OBJS += src/pltsql_partition.o

export ANTLR4_JAVA_BIN=java
export ANTLR4_RUNTIME_LIB=-lantlr4-runtime
export ANTLR4_RUNTIME_INCLUDE_DIR=/usr/local/include/antlr4-runtime
export ANTLR4_RUNTIME_LIB_DIR=/usr/local/lib

OBJS += src/pltsql_bulkcopy.o

PG_CXXFLAGS += -g -Werror -Wfloat-conversion
PG_CXXFLAGS += -Wno-deprecated -Wno-error=attributes -Wno-suggest-attribute=format # disable some warnings from ANTLR runtime header
PG_CXXFLAGS += -Wno-undef -Wall -Wcpp
PG_CXXFLAGS += -Wno-register # otherwise C++17 gags on PostgreSQL headers
PG_CXXFLAGS += -I$(ANTLR4_RUNTIME_INCLUDE_DIR)
PG_CXXFLAGS += -std=c++17
PG_CFLAGS += -g -Werror -Wfloat-conversion
PG_CFLAGS += -fstack-protector-strong
PG_CPPFLAGS += -I$(TSQLSRC) -I$(PG_SRC) -DFAULT_INJECTOR -Wfloat-conversion

SHLIB_LINK += -L$(ANTLR4_RUNTIME_LIB_DIR) $(ANTLR4_RUNTIME_LIB) -lcrypto $(ICU_LIBS)

UPGRADES = $(patsubst sql/upgrades/%.sql,sql/%.sql,$(wildcard sql/upgrades/*.sql))

REGRESS = test/babel_like
REGRESS += test/babel_219
REGRESS += test/babel_init
REGRESS += test/babel_select_distinct_top
REGRESS += test/babel_transaction
REGRESS += test/babel_typecode
REGRESS += test/babel_uniqueidentifier
REGRESS += test/babel_collation
REGRESS += test/babel_ddl
REGRESS += test/babel_delete
REGRESS += test/babel_set_command
REGRESS += test/babel_datatype
REGRESS += test/babel_function
REGRESS += test/babel_table_type
# REGRESS += test/babel_emoji          TODO: fix BABEL-3543

# We need the previous version to test extension upgrade scripts
ifdef PREV_EXTVERSION
DATA = sql/$(EXTENSION)--$(PREV_EXTVERSION).sql
endif

DATA_built = \
	$(EXTENSION).control \
	sql/$(EXTENSION)--$(EXTVERSION).sql $(UPGRADES)

#include ../Makefile.common

# Get Postgres version, as well as major (9.4, etc) version. Remove '.' from MAJORVER.
VERSION 	 = $(shell $(PG_CONFIG) --version | awk '{print $$2}' | sed -e 's/devel$$//')
MAJORVER 	 = $(shell echo $(VERSION) | cut -d . -f1,2 | tr -d .)

# Function for testing a condition
test		 = $(shell test $(1) $(2) $(3) && echo yes || echo no)

GE91		 = $(call test, $(MAJORVER), -ge, 91)

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

ifeq ($(GE91),yes)
all: sql/$(EXTENSION)--$(EXTVERSION).sql $(UPGRADES)
endif

$(EXTENSION).control: $(EXTENSION).control.in
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		| sed -e 's|@EXTENSION@|$(EXTENSION)|g' \
		| sed -e 's|@MODULEPATH@|$(MODULEPATH)|g' \
		> $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).in
	cpp -Werror $< | sed 's/^# /-- /g' > $@

sql/%.sql: sql/upgrades/%.sql
	cp $< $@


# $(KEYWORDS) should contain the name of each keyword
#       file

#KEYWORDS  = src/pl_reserved_kwlist.h
KEYWORDS = src/pl_reserved_kwlist_d.h
#KEYWORDS += src/pl_unreserved_kwlist.h
KEYWORDS += src/pl_unreserved_kwlist_d.h

#PERL := perl

# where to find gen_keywordlist.pl and subsidiary files
TOOLSDIR = $(PG_SRC)/src/tools
GEN_KEYWORDLIST = $(PERL) -I $(TOOLSDIR) $(TOOLSDIR)/gen_keywordlist.pl
GEN_KEYWORDLIST_DEPS = $(TOOLSDIR)/gen_keywordlist.pl $(TOOLSDIR)/PerfectHash.pm
TSQLSRC = .

antlr/Makefile: antlr/CMakeLists.txt antlr/TSqlLexer.g4 antlr/TSqlLexer.g4
	cd antlr && $(cmake) . && cd ..

.PHONY: antlr/libantlr_tsql.a  # to allow CMake's make check the build
antlr/libantlr_tsql.a: antlr/Makefile
	$(MAKE) -C $(@D) all

# See notes in src/backend/parser/Makefile about the following two rules
src/pl_gram.h: src/pl_gram.c
	touch $@

src/pl_gram.c: BISONFLAGS += -d -v

# generate plerrcodes.h: from src/backend/utils/errcodes.txt
src/plerrcodes.h: $(PG_SRC)/src/backend/utils/errcodes.txt src/generate-plerrcodes.pl
	echo $(top_srcdir)
	$(PERL) src/generate-plerrcodes.pl $< > $@

# generate keyword headers for the scanner
src/pl_reserved_kwlist_d.h: src/pl_reserved_kwlist.h $(GEN_KEYWORDLIST_DEPS)
	$(GEN_KEYWORDLIST) --varname ReservedPLKeywords $<

src/pl_unreserved_kwlist_d.h: src/pl_unreserved_kwlist.h $(GEN_KEYWORDLIST_DEPS)
	$(GEN_KEYWORDLIST) --varname UnreservedPLKeywords $<

src/pl_scanner.o: src/pl_scanner.c $(KEYWORDS)

src/pl_comp.o: src/plerrcodes.h

src/tsqlIface.o: src/tsqlIface.cpp

src/tsqlUnsupportedFeatureHandler.o: src/tsqlUnsupportedFeatureHandler.cpp

## extend backend parser
BEPARSERDIR=src/backend_parser

src/backend_parser/kwlist_d.h: src/backend_parser/kwlist.h $(GEN_KEYWORDLIST_DEPS)
	$(GEN_KEYWORDLIST) --output src/backend_parser --varname pgtsql_ScanKeywords $<

src/backend_parser/keywords.o: src/backend_parser/keywords.c src/backend_parser/kwlist_d.h

src/backend_parser/gram-backend.y: $(PG_SRC)/src/backend/parser/gram.y $(BEPARSERDIR)/gram-tsql-prologue.y.h $(BEPARSERDIR)/gram-tsql-decl.y $(BEPARSERDIR)/gram-tsql-rule.y $(BEPARSERDIR)/gram-tsql-epilogue.y.c $(BEPARSERDIR)/include.pl
	$(PERL) $(BEPARSERDIR)/include.pl $(BEPARSERDIR) gram.y < $< > $@

src/backend_parser/gram-backend.c: BISONFLAGS += -d

src/backend_parser/gram-backend.c: src/backend_parser/gram-backend.y

src/backend_parser/gram-backend.h: src/backend_parser/gram-backend.c
	touch $@

src/backend_parser/scan-backend.l: $(PG_SRC)/src/backend/parser/scan.l $(BEPARSERDIR)/scan-tsql-prologue-top.l.h $(BEPARSERDIR)/scan-tsql-prologue.l.h $(BEPARSERDIR)/scan-tsql-decl.l $(BEPARSERDIR)/scan-tsql-rule.l $(BEPARSERDIR)/scan-tsql-epilogue.l.c
	$(PERL) $(BEPARSERDIR)/include.pl $(BEPARSERDIR) scan.l < $< > $@

src/backend_parser/scan-backend.c: FLEXFLAGS = -CF -p -p
src/backend_parser/scan-backend.c: FLEX_NO_BACKUP=yes
src/backend_parser/scan-backend.c: FLEX_FIX_WARNING=yes

ifneq ("$(wildcard $(FLEX))","")
	FLEX_EXEC := $(FLEX)
else
	FLEX_EXEC := flex # if $(FLEX) doens't exists (postgres and extension can be built in different nodes), use built-in flex
endif

src/backend_parser/scan-backend.c: src/backend_parser/scan-backend.l
	$(FLEX_EXEC) $(if $(FLEX_NO_BACKUP),-b) $(FLEXFLAGS) -o'$@' $<
	@$(if $(FLEX_NO_BACKUP),if [ `wc -l <lex.backup` -eq 1 ]; then rm lex.backup; else echo "Scanner requires backup; see lex.backup." 1>&2;     exit 1; fi)
	$(if $(FLEX_FIX_WARNING),$(PERL) $(TOOLSDIR)/fix-old-flex-code.pl '$@')

# Force these dependencies to be known even without dependency info built:
src/backend_parser/gram-backend.o src/backend_parser/scan-backend.o src/backend_parser/parser.o: src/backend_parser/gram-backend.h

src/fts_parser.o: src/fts_scan.c src/fts_data.h
src/fts.o: src/fts_scan.c src/fts_parser.c src/fts_data.h
distprep: src/fts_scan.c src/fts_parser.c

include $(PGXS)

.DEFAULT_GOAL := all
.PHONY: sql/$(EXTENSION)--$(EXTVERSION).sql

################################################################################
## ANTLR Parser rules
################################################################################
# ANTLR = antlr4
# ANTLRFLAGS = -Dlanguage=Cpp -listener
#
# TSqlLexer.o : CXXFLAGS = -O -g -fpic -I/usr/local/include/antlr4-runtime -Wno-attributes -Wno-deprecated
# TSqlParser.o : CXXFLAGS = -O -g -fpic -I/usr/local/include/antlr4-runtime -Wno-attributes -Wno-deprecated
#
# TSqlParser.cpp:	TSqlParser.g4 TSqlLexer.g4
# 	$(ANTLR) $(ANTLRFLAGS) $<
#
# TSqlLexer.cpp: TSqlLexer.g4
# 	$(ANTLR) $(ANTLRFLAGS) $<
