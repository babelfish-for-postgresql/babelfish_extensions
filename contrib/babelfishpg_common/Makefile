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

PG_CFLAGS += -g -Werror -Wfloat-conversion
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
OBJS += src/spatialtypes.o
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

UPGRADES = $(patsubst sql/upgrades/babelfishpg_common--%.sql,sql/babelfishpg_common--%.sql,$(wildcard sql/upgrades/babelfishpg_common--*.sql))
GENERATED_UPGRADES = \
    sql/$(EXTENSION)--3.2.0--3.3.0.sql \
    sql/$(EXTENSION)--3.3.0--3.4.0.sql \
    sql/$(EXTENSION)--3.4.0--3.5.0.sql \
    sql/$(EXTENSION)--3.5.0--3.6.0.sql \
    sql/$(EXTENSION)--3.6.0--3.7.0.sql

ifdef PREV_EXTVERSION
DATA = sql/$(EXTENSION)--$(PREV_EXTVERSION).sql
endif

DATA_built = \
    $(EXTENSION).control \
    sql/$(EXTENSION)--$(EXTVERSION).sql $(UPGRADES) \
    $(GENERATED_UPGRADES)

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
all: $(GENERATED_UPGRADES)
endif

$(EXTENSION).control: $(EXTENSION).control.in
	cat $< \
		| sed -e 's|@EXTVERSION@|$(EXTVERSION)|g' \
		| sed -e 's|@EXTENSION@|$(EXTENSION)|g' \
		| sed -e 's|@MODULEPATH@|$(MODULEPATH)|g' \
		> $@

FLAG_TO_CHECK := -DENABLE_SPATIAL_TYPES

# Check if the flag is present in PG_CPPFLAGS
ifeq (,$(filter $(FLAG_TO_CHECK),$(PG_CPPFLAGS)))
# The flag is not present then build the .in file not including the spatial type files
    sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).in
		cpp -Werror $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.2.0--3.3.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D PREV_VERSION=3.2.0 -D CUR_VERSION=3.3.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.3.0--3.4.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D PREV_VERSION=3.3.0 -D CUR_VERSION=3.4.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.4.0--3.5.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D PREV_VERSION=3.4.0 -D CUR_VERSION=3.5.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.5.0--3.6.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D PREV_VERSION=3.5.0 -D CUR_VERSION=3.6.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.6.0--3.7.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D PREV_VERSION=3.6.0 -D CUR_VERSION=3.7.0 $< | sed 's/^# /-- /g' > $@

else
# The flag is present build the .in file including the spatial type files
    sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).in
		cpp -Werror -D ENABLE_SPATIAL_TYPES=1 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.2.0--3.3.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D ENABLE_SPATIAL_TYPES=1 -D PREV_VERSION=3.2.0 -D CUR_VERSION=3.3.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.3.0--3.4.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D ENABLE_SPATIAL_TYPES=1 -D PREV_VERSION=3.3.0 -D CUR_VERSION=3.4.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.4.0--3.5.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D ENABLE_SPATIAL_TYPES=1 -D PREV_VERSION=3.4.0 -D CUR_VERSION=3.5.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.5.0--3.6.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D ENABLE_SPATIAL_TYPES=1 -D PREV_VERSION=3.5.0 -D CUR_VERSION=3.6.0 $< | sed 's/^# /-- /g' > $@

    sql/$(EXTENSION)--3.6.0--3.7.0.sql: sql/upgrades/babelfishpg_upgrades.in
		cpp -D ENABLE_SPATIAL_TYPES=1 -D PREV_VERSION=3.6.0 -D CUR_VERSION=3.7.0 $< | sed 's/^# /-- /g' > $@

endif

sql/babelfishpg_common--%.sql: sql/upgrades/babelfishpg_common--%.sql
	cp $< $@


CFLAGS = `$(PG_CONFIG) --includedir-server`

$(recurse)
