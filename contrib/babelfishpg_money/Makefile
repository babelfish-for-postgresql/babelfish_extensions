MODULE_big = babelfishpg_money
OBJS = fixeddecimal.o

EXTENSION = babelfishpg_money

#subdir = contrib/babelfishpg_money

DATA = fixeddecimal--1.0.0--1.1.0.sql
DATA_built = babelfishpg_money--1.1.0.sql

#include ../Makefile.common

CFLAGS = `$(PG_CONFIG) --includedir-server`

TESTS = $(wildcard test/sql/*.sql)

REGRESS_BRIN := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "XL 9\.[5-9]| 10\.0| 11\.[0-9]| 12\.[0-9]" && echo brin-xl)
REGRESS_BRIN += $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -E "9\.[5-9]| 10\.0| 11\.[0-9]| 12\.[0-9]" | grep -qEv "XL" && echo brin)
REGRESS_VERSION_SPECIFIC := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "XL" && echo index-xl || echo index)
REGRESS = $(shell echo aggregate cast comparison overflow $(REGRESS_BRIN) $(REGRESS_VERSION_SPECIFIC))

REGRESS_OPTS = --inputdir=test --outputdir=test --load-extension=babelfishpg_money

#PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

AGGSTATESQL := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "XL" && echo fixeddecimalaggstate.sql)
AGGFUNCSSQL := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "XL" && echo fixeddecimal--xlaggs.sql)

AGGFUNCSSQL := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "9\.[6-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]" && echo fixeddecimal--parallelaggs.sql || echo fixeddecimal--aggs.sql)

BRINSQL := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "9\.[5-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]" && echo fixeddecimal--brin.sql)

# 9.6 was the dawn of parallel query, so we'll use the parallel enabled .sql file from then on.
BASESQL := $(shell LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) $(PG_CONFIG) --version | grep -qE "9\.[6-9]| 10\.[0-9]| 11\.[0-9]| 12\.[0-9]" && echo fixeddecimal--1.1.0_base_parallel.sql || echo fixeddecimal--1.1.0_base.sql)

OBJECTS := $(addprefix $(srcdir)/, $(AGGSTATESQL) $(BASESQL) $(AGGFUNCSSQL) $(BRINSQL))

babelfishpg_money--1.1.0.sql: $(OBJECTS)
	cat $^ > $@
