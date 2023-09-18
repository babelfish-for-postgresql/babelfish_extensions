MODULE_big = babelfishpg_unit
EXTENSION = babelfishpg_unit     # the extension's name
DATA = babelfishpg_unit--1.0.0.sql    # script file to install
OBJS = $(SRCS:.c=.o)       # object files

 # source code files
SRCS    = babelfishpg_unit.c test_money.c \

# for posgres build
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
