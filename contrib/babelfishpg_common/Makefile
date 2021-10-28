include Version.config

EXTENSION = babelfishpg_common
EXTVERSION = $(BBFPGCMN_MAJOR_VERSION).$(BBFPGCMN_MINOR_VERSION).$(BBFPGCMN_MICRO_VERSION)

MODULEPATH = $$libdir/$(EXTENSION)-$(BBFPGCMN_MAJOR_VERSION)
MODULE_big = $(EXTENSION)

PG_CFLAGS += -g

ifdef PREV_EXTVERSION
DATA = sql/$(EXTENSION)--$(PREV_EXTVERSION).sql
endif

DATA_built = \
    $(EXTENSION).control \
    sql/$(EXTENSION)--$(EXTVERSION).sql

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

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

MODULEPATH = $$libdir/$(EXTENSION)-$(BBFPGCMN_MAJOR_VERSION)

ifdef PREV_EXTVERSION
DATA = sql/$(EXTENSION)--$(PREV_EXTVERSION).sql
endif

DATA_built = \
    $(EXTENSION).control \
    sql/$(EXTENSION)--$(EXTVERSION).sql $(UPGRADES)

#include ../Makefile.common

$(EXTENSION).control: $(EXTENSION).control.in
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		| sed -e 's|@EXTENSION@|$(EXTENSION)|g' \
		| sed -e 's|@MODULEPATH@|$(MODULEPATH)|g' \
		> $@

sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).in
	cpp $< | sed 's/^# /-- /g' > $@


CFLAGS = `$(PG_CONFIG) --includedir-server`

$(recurse)
