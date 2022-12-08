include Version.config

EXTENSION = babelfishpg_common
EXTVERSION = $(BBFPGCMN_MAJOR_VERSION).$(BBFPGCMN_MINOR_VERSION).$(BBFPGCMN_MICRO_VERSION)

# Note:
#	Set PREV_EXTVERSION after release, i.e after release of 2.0.0, set PREV_EXTVERSION to 1.0.0
#	babel_upgrade test target should at the top of the src/test/regress/babel_schedule
#		src/test/regress/sql/babel_upgrade.sql should be modified to include the PREV_EXTVERSION to test the upgrade path
#		contrib/babelfishpg_tsql/sql/upgrades/$(EXTENSION)--$(PREV_EXTVERSION).sql should be present to test the upgrade path
PREV_EXTVERSION = 1.0.0
MODULEPATH = $$libdir/$(EXTENSION)-$(BBFPGCMN_MAJOR_VERSION)
MODULE_big = $(EXTENSION)

PG_CFLAGS += -g -Werror
PG_CFLAGS += -fstack-protector-strong
ifdef PREV_EXTVERSION
DATA = sql/$(EXTENSION)--$(PREV_EXTVERSION).sql
endif

DATA_built = \
    $(EXTENSION).control \
    sql/$(EXTENSION)--$(EXTVERSION).sql

PG_CPPFLAGS += -I$(PG_SRC)

OBJS  = src/babelfishpg_common.o
OBJS += src/varchar.o
OBJS += src/bit.o
OBJS += src/instr.o
OBJS += src/typecode.o
OBJS += src/numeric.o
OBJS += src/varbinary.o
OBJS += src/uniqueidentifier.o
OBJS += src/datetime.o
OBJS += src/datetime2.o
OBJS += src/smalldatetime.o
OBJS += src/datetimeoffset.o
OBJS += src/sqlvariant.o
OBJS += src/coerce.o
OBJS += src/collation.o
OBJS += src/encoding/encoding_utils.o
OBJS += src/encoding/mb/conv.o
OBJS += src/encoding/mb/conversion_procs/utf8_and_big5/utf8_and_big5.o
OBJS += src/encoding/mb/conversion_procs/utf8_and_gbk/utf8_and_gbk.o
OBJS += src/encoding/mb/conversion_procs/utf8_and_sjis/utf8_and_sjis.o
OBJS += src/encoding/mb/conversion_procs/utf8_and_uhc/utf8_and_uhc.o
OBJS += src/encoding/mb/conversion_procs/utf8_and_win/utf8_and_win.o

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

MODULEPATH = $$libdir/$(EXTENSION)-$(BBFPGCMN_MAJOR_VERSION)

UPGRADES = $(patsubst sql/upgrades/%.sql,sql/%.sql,$(wildcard sql/upgrades/*.sql))

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

install: install-lib link-lib
uninstall: uninstall-lib unlink-lib

# Also add .so file to libdir so that other extensions can link to it.
link-lib:
ifneq ($(pkglibdir), $(libdir))
	ln -sf $(pkglibdir)/$(EXTENSION).so $(libdir)/$(EXTENSION).so
endif

unlink-lib:
ifneq ($(pkglibdir), $(libdir))
	rm -f $(libdir)/$(EXTENSION).so
endif

$(EXTENSION).control: $(EXTENSION).control.in
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		| sed -e 's|@EXTENSION@|$(EXTENSION)|g' \
		| sed -e 's|@MODULEPATH@|$(MODULEPATH)|g' \
		> $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).in
	cpp $< | sed 's/^# /-- /g' > $@

sql/%.sql: sql/upgrades/%.sql
	cp $< $@


CFLAGS = `$(PG_CONFIG) --includedir-server`

$(recurse)
