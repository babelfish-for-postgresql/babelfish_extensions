# contrib/babelfishpg_tds/Makefile
MODULE_big = babelfishpg_tds
EXTENSION = babelfishpg_tds
DATA = babelfishpg_tds--1.0.0.sql
PGFILEDESC = "babelfishpg_tds - TDS Listener Extension"
#REGRESS = babelfishpg_tds

tds_top_dir = .
tds_backend = $(tds_top_dir)/src/backend
tds_include = $(tds_top_dir)/src/include
TSQL_SRC = ../babelfishpg_tsql

PG_CPPFLAGS += -I$(TSQL_SRC) -I$(PG_SRC) -I$(tds_top_dir) -DFAULT_INJECTOR -Werror

# Exclude the following files from the build (sometimes these
# files are included in another c file)
tds_exclude_files = $(tds_backend)/tds/support_funcs.c \
					$(tds_backend)/tds/tds_data_map.c \
					$(tds_backend)/tds/tdsprinttup.c

tds_temp_srcs = $(shell find $(tds_top_dir) -name "*.c")
tds_srcs = $(filter-out $(tds_exclude_files), $(tds_temp_srcs))

OBJS = $(patsubst %.c, %.o, $(tds_srcs))
OBJS += $(WIN32RES)

$(tds_include)/error_mapping.h: error_mapping.txt generate_error_mapping.pl
	$(PERL) generate_error_mapping.pl $< > $@
$(tds_backend)/tds/err_handler.o: $(tds_include)/error_mapping.h

# Disable for now
#NO_PGXS = 1

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

#include ../Makefile.common

.DEFAULT_GOAL := all
