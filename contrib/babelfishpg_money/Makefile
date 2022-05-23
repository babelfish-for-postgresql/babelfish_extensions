MODULE_big = babelfishpg_money
OBJS = fixeddecimal.o

EXTENSION = babelfishpg_money

DATA = fixeddecimal--1.0.0--1.1.0.sql
DATA_built = babelfishpg_money--1.1.0.sql

ifdef USE_PGXS
VERSION = $(shell $(PG_CONFIG) --version)
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = babelfish_extensions/contrib/babelfishpg_money
top_builddir = ../../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

TESTS = $(wildcard test/sql/*.sql)

REGRESS_BRIN := $(shell echo $(VERSION) | grep -qE "XL 9\.[5-9]| 10\.0| 11\.[0-9]| 12\.[0-9]| 13\.[0-9]" && echo brin-xl)
REGRESS_BRIN += $(shell echo $(VERSION) | grep -E "9\.[5-9]| 10\.0| 11\.[0-9]| 12\.[0-9]| 13\.[0-9]" | grep -qEv "XL" && echo brin)
REGRESS_VERSION_SPECIFIC := $(shell echo $(VERSION) | grep -qE "XL" && echo index-xl || echo index)
REGRESS = $(shell echo aggregate cast comparison overflow $(REGRESS_BRIN) $(REGRESS_VERSION_SPECIFIC))

REGRESS_OPTS = --inputdir=test --outputdir=test --load-extension=babelfishpg_money

AGGSTATESQL := $(shell echo $(VERSION) | grep -qE "XL" && echo fixeddecimalaggstate.sql)
AGGFUNCSSQL := $(shell echo $(VERSION) | grep -qE "XL" && echo fixeddecimal--xlaggs.sql)

AGGFUNCSSQL := $(shell echo $(VERSION) | grep -qE "9\.[6-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]| 13\.[0-9]" && echo fixeddecimal--parallelaggs.sql || echo fixeddecimal--aggs.sql)

BRINSQL := $(shell echo $(VERSION) | grep -qE "9\.[5-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]| 13\.[0-9]" && echo fixeddecimal--brin.sql)

# 9.6 was the dawn of parallel query, so we'll use the parallel enabled .sql file from then on.
BASESQL := $(shell echo $(VERSION) | grep -qE "9\.[6-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]| 13\.[0-9]" && echo fixeddecimal--1.1.0_base_parallel.sql || echo fixeddecimal--1.1.0_base.sql)

OBJECTS := $(addprefix $(srcdir)/, $(AGGSTATESQL) $(BASESQL) $(AGGFUNCSSQL) $(BRINSQL))

babelfishpg_money--1.1.0.sql: $(OBJECTS)
	cat $^ > $@
