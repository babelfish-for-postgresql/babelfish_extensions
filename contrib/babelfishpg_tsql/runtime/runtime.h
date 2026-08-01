#include "postgres.h"
#include "port.h"
#include "funcapi.h"
#include "pgstat.h"
#include "varatt.h"

#include "postgres.h"
#include "access/hash.h"
#include "access/nbtree.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "libpq/pqformat.h"
#include "utils/timestamp.h"
#include "utils/formatting.h"

#include "fmgr.h"
#include "miscadmin.h"

#include "access/detoast.h"
#include "access/htup_details.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_database.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_type.h"
#include "catalog/pg_attrdef.h"
#include "catalog/pg_depend.h"
#include "commands/dbcommands.h"
#include "commands/extension.h"
#include "common/md5.h"
#include "executor/spi.h"
#include "executor/spi_priv.h"
#include "miscadmin.h"
#include "parser/scansup.h"
#include "tsearch/ts_locale.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/elog.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/numeric.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "utils/queryenvironment.h"
#include "utils/float.h"
#include "utils/xid8.h"
#include "utils/xml.h"
#include <math.h>

#include "../src/babelfish_version.h"
#include "../src/datatype_info.h"
#include "../src/pltsql.h"
#include "../src/pltsql_instr.h"
#include "../src/multidb.h"
#include "../src/session.h"
#include "../src/catalog.h"
#include "../src/timezone.h"
#include "../src/collation.h"
#include "../src/dbcmds.h"
#include "../src/hooks.h"
#include "../src/rolecmds.h"
#include "utils/fmgroids.h"
#include "utils/acl.h"
#include "access/table.h"
#include "access/genam.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_constraint.h"
#include "parser/parse_oper.h"

#define xpfree(var_) \
	do { \
		if (var_ != NULL) \
		{ \
			pfree(var_); \
			var_ = NULL; \
		} \
	} while (0)	

#define xpstrdup(tgtvar_, srcvar_) \
	do { \
		if (srcvar_) \
			tgtvar_ = pstrdup(srcvar_); \
		else \
			tgtvar_ = NULL; \
	} while (0)

#define xstreq(tgtvar_, srcvar_) \
	(((tgtvar_ == NULL) && (srcvar_ == NULL)) || \
	 ((tgtvar_ != NULL) && (srcvar_ != NULL) && (strcmp(tgtvar_, srcvar_) == 0)))
