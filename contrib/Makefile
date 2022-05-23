# contrib/Makefile

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = babelfish_extensions/contrib
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
endif

SUBDIRS = \
		babelfishpg_common \
		babelfishpg_money \
		babelfishpg_tds \
		babelfishpg_tsql

all: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@

.PHONY: all $(SUBDIRS)

$(recurse)
$(recurse_always)

