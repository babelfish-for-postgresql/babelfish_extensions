#include "postgres.h"

#include "access/printtup.h"
#include "catalog/namespace.h"
#include "catalog/pg_type.h"
#include "executor/spi.h"
#include "libpq/libpq-be.h"
#include "miscadmin.h"
#include "parser/parse_expr.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"
#include "utils/tuplestore.h"

#include "pltsql.h"
#include "pltsql-2.h"

extern PLtsql_execstate *get_current_tsql_estate(void);
extern void assign_text_var(PLtsql_execstate *estate, PLtsql_var *var, const char *str);

/* cursor handle */
const uint32 CURSOR_HANDLE_INVALID = 0xABCDEF0; /* magic number used in T-SQL */
static uint32 current_cursor_handle;
uint32		get_next_cursor_handle(void);

const uint32 CURSOR_PREPARED_HANDLE_START = 1073741824;
const uint32 CURSOR_PREPARED_HANDLE_INVALID = 0xFFFFFFFF;
static int	current_cursor_prepared_handle;
uint32		get_next_cursor_prepared_handle(void);

/* functions called in pl_exec */
bool		pltsql_declare_cursor(PLtsql_execstate *estate, PLtsql_var *var, PLtsql_expr *explicit_expr, int cursor_options);
void		pltsql_init_anonymous_cursors(PLtsql_execstate *estate);
void		pltsql_cleanup_local_cursors(PLtsql_execstate *estate);

char	   *pltsql_demangle_curname(char *curname);

/* sp_cursor parameter handling */
static lookup_param_hook_type prev_lookup_param_hook;
static List *sp_cursor_params = NIL;

static Node *sp_cursor_find_param(ParseState *pstate, ColumnRef *cref);

void		enable_sp_cursor_find_param_hook(void);
void		disable_sp_cursor_find_param_hook(void);
void		add_sp_cursor_param(char *name);
void		reset_sp_cursor_params(void);

/* cursor information hashtab */
typedef struct cursorhashent
{
	char		curname[NAMEDATALEN + 1];
	PLtsql_expr *explicit_expr;
	uint32		cursor_options;
	int16		fetch_status;
	int16		last_operation;
	uint64		row_count;
	int32		cursor_handle;
	bool		api_cursor;		/* only used in cursor_list now. can be
								 * deprecated once we supprot global cursor */
	TupleDesc	tupdesc;
	Tuplestorestate *fetch_buffer;
	char	   *textptr_only_bitmap;
} CursorHashEnt;

static HTAB *CursorHashTable = NULL;

typedef struct CursorPreparedHandleHashEnt
{
	uint32		handle;
	SPIPlanPtr	plan;
	int			cursor_options;
} CursorPreparedHandleHashEnt;

static HTAB *CursorPreparedHandleHashTable = NULL;

static MemoryContext CursorHashtabContext = NULL;

/* cursor hashtab operations */
void		pltsql_create_cursor_htab(void);
CursorHashEnt *pltsql_insert_cursor_entry(char *curname, PLtsql_expr *explicit_expr, int cursor_options, int *cursor_handle);
void		pltsql_delete_cursor_entry(char *curname, bool missing_ok);
void		pltsql_get_cursor_definition(char *curname, PLtsql_expr **explicit_expr, int *cursor_options);
void		pltsql_update_cursor_fetch_status(char *curname, int fetch_status);
void		pltsql_update_cursor_row_count(char *curname, int64 row_count);
void		pltsql_update_cursor_last_operation(char *curname, int last_operation);

static const char *LOCAL_CURSOR_INFIX = "##sys_gen##";

bool		is_cursor_datatype(Oid oid);
static Oid	tsql_cursor_oid = InvalidOid;
static Oid	lookup_tsql_cursor_oid(void);

/* keep the name of last opened cursor name for @@cursor_rows */
static char last_opened_cursor[NAMEDATALEN + 1];

/* implementation function shared between cursor functions and procedures */
static int	cursor_status_impl(PLtsql_var *var);
static int	cursor_status_impl2(const char *curname);
static int	cursor_rows_impl(const char *curname);
static int	cursor_column_count_impl(const char *curname);

static int	execute_sp_cursoropen_common(int *stmt_handle, int *cursor_handle, const char *stmt, int *pscrollopt, int *pccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls, bool prepare, bool save_plan, bool execute);
static void validate_sp_cursor_params(int opttype, int rownum, const char *tablename, List *values);
static int	validate_and_get_sp_cursoropen_params(int scrollopt, int ccopt);
static void validate_and_get_sp_cursorfetch_params(int *fetchtype_in, int *rownum_in, int *nrows_in, int *fetchtype_out, int *rownum_out, int *nrows_out);
static void validate_sp_cursoroption_params(int code, int value);

/* cursor functions and procedures */
PG_FUNCTION_INFO_V1(cursor_rows);
PG_FUNCTION_INFO_V1(cursor_status);
PG_FUNCTION_INFO_V1(cursor_list);

PG_FUNCTION_INFO_V1(init_tsql_cursor_hash_tab);

/* helper function for debugging/testing */
PG_FUNCTION_INFO_V1(pltsql_cursor_show_textptr_only_column_indexes);
PG_FUNCTION_INFO_V1(pltsql_get_last_cursor_handle);
PG_FUNCTION_INFO_V1(pltsql_get_last_stmt_handle);

/* Start of implementation */
uint32
get_next_cursor_handle()
{
	char		curname[NAMEDATALEN];
	uint32		old_handle = current_cursor_handle;

	while (true)
	{
		++current_cursor_handle;
		if (current_cursor_handle == CURSOR_HANDLE_INVALID)
			++current_cursor_handle;
		if (unlikely(current_cursor_handle == old_handle))
			elog(ERROR, "out of sp cursor handles");
		snprintf(curname, NAMEDATALEN, "%u", current_cursor_handle);
		if (hash_search(CursorHashTable, curname, HASH_FIND, NULL) == NULL)
			break;				/* found */
	}
	return current_cursor_handle;
}

uint32
get_next_cursor_prepared_handle()
{
	uint32		old_handle = current_cursor_prepared_handle;

	while (true)
	{
		++current_cursor_prepared_handle;
		if (current_cursor_prepared_handle == CURSOR_PREPARED_HANDLE_INVALID)
			++current_cursor_prepared_handle;
		if (unlikely(current_cursor_prepared_handle == old_handle))
			elog(ERROR, "out of sp cursor prepared handles");
		if (hash_search(CursorPreparedHandleHashTable, &current_cursor_prepared_handle, HASH_FIND, NULL) == NULL)
			break;				/* found */
	}

	return current_cursor_prepared_handle;
}

bool
is_cursor_datatype(Oid oid)
{
	if (oid == REFCURSOROID)
		return true;

	if (tsql_cursor_oid == InvalidOid)
		tsql_cursor_oid = lookup_tsql_cursor_oid();

	return tsql_cursor_oid == oid;
}

static Oid
lookup_tsql_cursor_oid()
{
	Oid			nspoid;
	Oid			typoid;

	nspoid = get_namespace_oid("sys", true);
	if (nspoid == InvalidOid)
		return InvalidOid;

	typoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("cursor"), ObjectIdGetDatum(nspoid));
	return typoid;
}

bool
pltsql_declare_cursor(PLtsql_execstate *estate, PLtsql_var *var, PLtsql_expr *explicit_expr, int cursor_options)
{
	char	   *curname;
	CursorHashEnt *hentry;
	Portal		portal;
	char		mangled_name[NAMEDATALEN];

	if (!var->isnull)
	{
		curname = TextDatumGetCString(var->value);

		hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
		if (hentry != NULL)		/* already declared */
		{
			portal = SPI_cursor_find(hentry->curname);
			if (portal != NULL)
				return false;	/* already opened portal */

			if (hentry->last_operation != 7)
				return false;	/* not dealloc'd */

			pltsql_delete_cursor_entry(curname, false);
		}
	}

	/*
	 * For local cursor, the same cursor name may be already taken by parent
	 * function/procedure To avoid conflict, generate a unique name by using
	 * var pointer.
	 *
	 * SPI proc memory context is used here intentionally. It will be
	 * destoryed at the end of function/procedure call. It has the same
	 * lifecycle with LOCAL cursor by its definition. When we implement GLOBAL
	 * cursor, its lifespan is longer so we have to use different memory
	 * context.
	 */
	Assert(var->refname != NULL);
	if (strlen(var->refname) + strlen(LOCAL_CURSOR_INFIX) + 19 > NAMEDATALEN)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("internal cursor name is too long: %s", var->refname)));

	snprintf(mangled_name, NAMEDATALEN, "%s%s%p", var->refname, LOCAL_CURSOR_INFIX, var);

	assign_text_var(estate, var, mangled_name);
	var->cursor_explicit_expr = explicit_expr;
	var->cursor_options = cursor_options;

	curname = TextDatumGetCString(var->value);
	pltsql_insert_cursor_entry(mangled_name, explicit_expr, cursor_options, NULL);

	return true;
}

void
pltsql_init_anonymous_cursors(PLtsql_execstate *estate)
{
	/*
	 * This a rountine to handle anonymous (impliicitly declaring cursor via
	 * SET @curvar = CURSOR FOR <query>)
	 */

	char	   *curname;
	int			cursor_options;
	int			i;

	/*
	 * find cursor variables, assign cursor name and put cursor information to
	 * cursor hash.
	 */
	for (i = 0; i < estate->ndatums; ++i)
	{
		if (estate->datums[i]->dtype == PLTSQL_DTYPE_VAR)
		{
			PLtsql_var *var = (PLtsql_var *) estate->datums[i];

			if (is_cursor_datatype(var->datatype->typoid) &&
				var->isconst && /* if cursor variable, it means it just refers
								 * to another constant cursor. skip it */
				!(var->cursor_options & TSQL_CURSOR_OPT_GLOBAL) &&	/* GLOBAL cursor is not
																	 * supported yet */
				var->cursor_options & PGTSQL_CURSOR_ANONYMOUS)
			{
				Assert(var->isnull);

				/* Anonymous cursor already has sys-generated name. Use it */
				assign_text_var(estate, var, var->refname);
				curname = TextDatumGetCString(var->value);

				/*
				 * remove PGTSQL_ANONYMOUS_CURSOR from cursor option since the
				 * entry can be shared among with refcursor
				 */
				cursor_options = (var->cursor_options & ~PGTSQL_CURSOR_ANONYMOUS);
				pltsql_insert_cursor_entry(curname, var->cursor_explicit_expr, cursor_options, NULL);
			}
		}
	}
}

void
pltsql_cleanup_local_cursors(PLtsql_execstate *estate)
{
	Portal		portal;
	char	   *curname;
	int			i;

	/* close local cursor made by this estate */
	for (i = 0; i < estate->ndatums; ++i)
	{
		if (estate->datums[i]->dtype == PLTSQL_DTYPE_VAR)
		{
			PLtsql_var *var = (PLtsql_var *) estate->datums[i];

			if (is_cursor_datatype(var->datatype->typoid) &&
				var->isconst && /* if cursor variable, it means it just refers
								 * to another constant cursor. skip it */
				!var->isnull &&
				!(var->cursor_options & TSQL_CURSOR_OPT_GLOBAL))
			{
				curname = TextDatumGetCString(var->value);
				portal = SPI_cursor_find(curname);
				if (portal)
				{
					if (portal->portalPinned)	/* LOCAL cursor should be
												 * closed/deallocated at the
												 * end of block. unpin portal
												 * if already pinned */
						UnpinPortal(portal);

					SPI_cursor_close(portal);
				}
				pltsql_delete_cursor_entry(curname, false);
			}
		}
	}
}

char *
pltsql_demangle_curname(char *curname)
{
	char	   *infix_substr;
	char	   *p;
	char	   *p2;
	Size		len;

	if (curname == NULL)
		return NULL;

	infix_substr = NULL;
	p = curname;

	/*
	 * cursor name given from user may contain LOCAL_CURSOR_INFIX. find the
	 * last LOCAL_CURSOR_INFIX
	 */
	while ((p2 = strstr(p, LOCAL_CURSOR_INFIX)) != NULL)
	{
		infix_substr = p2;
		p = p2 + strlen(LOCAL_CURSOR_INFIX);
	}

	if (infix_substr == NULL)
		return curname;			/* can't find LOCAL_CURSOR_INFIX */

	len = infix_substr - curname;
	return pnstrdup(curname, len);
}

/*
 * sp_cursor parameter handling
 *
 * Other than sp_prepare series using inline_handler,
 * sp_cursor series need to exploit lower level SPI routine but its interface doesn't input a hook to handle parameters
 *
 * We will exploit exisiting lookup_param_hook to match parameter name.
 * This hook is already used to sp_cursor series call via TDS RPC (not a procedure call)
 * so sp_cursor behavior will be consistent regardless of whther it is called by EXEC in language side or TDS RPC directly.
 */

Node *
sp_cursor_find_param(ParseState *pstate, ColumnRef *cref)
{
	ParamRef   *pref;
	char	   *colname;
	ListCell   *cell;
	int			i = 1;
	int			param_no = 0;
	Node	   *result;

	if (prev_lookup_param_hook)
	{
		Node	   *found = (*prev_lookup_param_hook) (pstate, cref);

		if (found)
			return found;
	}

	if (list_length(cref->fields) != 1)
		return NULL;

	if (sp_cursor_params == NIL)
		return NULL;

	colname = strVal(linitial(cref->fields));
	foreach(cell, sp_cursor_params)
	{
		const char *param_name = lfirst(cell);

		if (pg_strcasecmp(colname, param_name) == 0)
		{
			param_no = i;
			break;
		}
		++i;
	}

	if (param_no == 0)
		return NULL;			/* not found */

	pref = makeNode(ParamRef);
	pref->number = param_no;
	pref->location = cref->location;

	/*
	 * The core parser knows nothing about Params.  If a hook is supplied,
	 * call it.  If not, or if the hook returns NULL, throw a generic error.
	 */
	if (pstate->p_paramref_hook != NULL)
		result = pstate->p_paramref_hook(pstate, pref);

	else
		result = NULL;

	if (result == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_PARAMETER),
				 errmsg("there is no parameter $%d", pref->number),
				 parser_errposition(pstate, pref->location)));

	return result;
}

void
enable_sp_cursor_find_param_hook()
{
	prev_lookup_param_hook = lookup_param_hook;
	lookup_param_hook = sp_cursor_find_param;
}

void
disable_sp_cursor_find_param_hook()
{
	lookup_param_hook = prev_lookup_param_hook;
	prev_lookup_param_hook = NULL;
}

void
add_sp_cursor_param(char *name)
{
	sp_cursor_params = lappend(sp_cursor_params, name);
}

void
reset_sp_cursor_params()
{
	sp_cursor_params = NIL;
}

void
pltsql_create_cursor_htab()
{
	HASHCTL		ctl;

	if (CursorHashtabContext == NULL)	/* intialize memory context */
	{
		CursorHashtabContext = AllocSetContextCreateInternal(NULL, "PLtsql Cursor hashtab Memory Context", ALLOCSET_DEFAULT_SIZES);
	}

	/* CursorHashTable */
	MemSet(&ctl, 0, sizeof(ctl));
	ctl.keysize = NAMEDATALEN;
	ctl.entrysize = sizeof(CursorHashEnt);
	ctl.hcxt = CursorHashtabContext;

	CursorHashTable = hash_create("T-SQL cursor information", 16 /* PORTALS_PER_USER */ , &ctl, HASH_ELEM | HASH_STRINGS | HASH_CONTEXT);

	current_cursor_handle = CURSOR_HANDLE_INVALID;

	/* CursorPreparedHandleHashTable */
	MemSet(&ctl, 0, sizeof(ctl));
	ctl.keysize = sizeof(uint32);
	ctl.entrysize = sizeof(CursorPreparedHandleHashEnt);
	ctl.hcxt = CursorHashtabContext;

	CursorPreparedHandleHashTable = hash_create("T-SQL cursor prepared handle", 16 /* PORTALS_PER_USER */ , &ctl, HASH_ELEM | HASH_BLOBS | HASH_CONTEXT);

	current_cursor_prepared_handle = CURSOR_PREPARED_HANDLE_START;
}

CursorHashEnt *
pltsql_insert_cursor_entry(char *curname, PLtsql_expr *explicit_expr, int cursor_options, int *cursor_handle)
{
	CursorHashEnt *hentry;
	bool		found;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_ENTER, &found);
	if (found)
		elog(ERROR, "duplicate cursor name");

	curname[0] = '\0';
	strncat(hentry->curname, curname, NAMEDATALEN);
	hentry->explicit_expr = explicit_expr;
	hentry->cursor_options = cursor_options;
	hentry->fetch_status = -9;
	hentry->row_count = 0;
	hentry->last_operation = 0;
	if (cursor_handle)			/* use given cursor_handle. mostly api cursor */
		hentry->cursor_handle = *cursor_handle;
	else						/* assign a new cursor handle. mostly language
								 * cursor */
		hentry->cursor_handle = get_next_cursor_handle();
	hentry->api_cursor = false;
	hentry->tupdesc = NULL;
	hentry->fetch_buffer = NULL;
	hentry->textptr_only_bitmap = NULL;

	return hentry;
}

void
pltsql_delete_cursor_entry(char *curname, bool missing_ok)
{
	CursorHashEnt *hentry;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry && hentry->tupdesc)
	{
		FreeTupleDesc(hentry->tupdesc);
		hentry->tupdesc = NULL;
	}

	if (hentry && hentry->fetch_buffer)
	{
		tuplestore_end(hentry->fetch_buffer);
		hentry->fetch_buffer = NULL;
	}

	if (hentry && hentry->textptr_only_bitmap)
	{
		pfree(hentry->textptr_only_bitmap);
		hentry->textptr_only_bitmap = NULL;
	}

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_REMOVE, NULL);
	if (!missing_ok && hentry == NULL)
		elog(WARNING, "trying to delete cursor name that does not exist");
}

void
pltsql_get_cursor_definition(char *curname, PLtsql_expr **explicit_expr, int *cursor_options)
{
	CursorHashEnt *hentry;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry)
	{
		*explicit_expr = hentry->explicit_expr;
		*cursor_options = hentry->cursor_options;
	}
	else
	{
		*explicit_expr = NULL;
		*cursor_options = 0;
	}
}

void
pltsql_update_cursor_fetch_status(char *curname, int fetch_status)
{
	CursorHashEnt *hentry;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry)
		hentry->fetch_status = fetch_status;
}

void
pltsql_update_cursor_row_count(char *curname, int64 row_count)
{
	CursorHashEnt *hentry;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry)
		hentry->row_count = row_count;
}

void
pltsql_update_cursor_last_operation(char *curname, int last_operation)
{
	CursorHashEnt *hentry;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry)
		hentry->last_operation = last_operation;

	/* keep the last opened cursor for @@cursor_rows */
	if (last_operation == 1)	/* open */
	{
		last_opened_cursor[0] = '\0';
		strncat(last_opened_cursor, curname, NAMEDATALEN);
	}
}

/* @@cursor_rows returns cursor_rows of 'last opened' cursor. */
Datum
cursor_rows(PG_FUNCTION_ARGS)
{
	if (strlen(last_opened_cursor) == 0)
		PG_RETURN_INT32(0);

	PG_RETURN_INT32(cursor_rows_impl(last_opened_cursor));
}

Datum
cursor_status(PG_FUNCTION_ARGS)
{
	PLtsql_execstate *estate;
	char	   *curtype;
	char	   *refname;
	int			i;

	/* get current tsql estate */
	estate = get_current_tsql_estate();
	if (estate == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("cursor_status() cannot access execution state")));

	curtype = text_to_cstring(PG_GETARG_TEXT_PP(0));
	refname = text_to_cstring(PG_GETARG_TEXT_PP(1));

	if (strcasecmp(curtype, "global") == 0)
	{
		/* GLOBAL cursor is not supported yet. We will find nothing */
		PG_RETURN_INT32(-3);
	}

	if ((strcasecmp(curtype, "local") != 0) && (strcasecmp(curtype, "variable") != 0))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("cursor_status() has an invalid parameter for cursor_source")));

	/* scan all the variables in top estate */
	for (i = 0; i < estate->ndatums; i++)
	{
		if (estate->datums[i]->dtype == PLTSQL_DTYPE_VAR)
		{
			PLtsql_var *var = (PLtsql_var *) estate->datums[i];

			if (is_cursor_datatype(var->datatype->typoid) && strcasecmp(var->refname, refname) == 0)
			{
				/* ignore cursor not matching with cursor source */
				if ((strcasecmp(curtype, "local") == 0) && !var->isconst)
					continue;
				if ((strcasecmp(curtype, "variable") == 0) && var->isconst)
					continue;

				PG_RETURN_INT32(cursor_status_impl(var));
			}
		}
	}

	/* cannot find corresponding cursor */
	PG_RETURN_INT32(-3);
}

static int
cursor_status_impl(PLtsql_var *var)
{
	char	   *curname;

	if (var->isnull)
	{
		return -2;
	}

	curname = TextDatumGetCString(var->value);
	return cursor_status_impl2(curname);
}

static int
cursor_status_impl2(const char *curname)
{
	CursorHashEnt *hentry;
	Portal		portal;

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("cursor_status() cannot find cursor entry")));

	if (hentry->last_operation == 7)	/* dealloc'd */
		return -3;

	portal = SPI_cursor_find(curname);
	if (portal == NULL)
	{
		/* cursor is not opened or already closed */
		return -1;
	}
	else
	{
		/*
		 * Note: For STATIC and KEYSET CURSOR, TSQL CURSOR_STATUS() can return
		 * 0 if result set is empty even though cursor is not fetched yet. It
		 * is thought that it's because T-SQL store the result set (full or
		 * key only) to temporary storage when cursor is opened. PG doesn't
		 * behave like that for INSENSTIVE (=STATIC) cursor (maybe by virtue
		 * of its MVCC) Hence, always return 1 here for now. It will be
		 * discussed further with DBE, and documented if needed.
		 */
		return 1;
	}
}

static int
cursor_rows_impl(const char *curname)
{
	Portal		portal;

	portal = SPI_cursor_find(curname);
	if (portal == NULL)
	{
		/* cursor is not opened or already closed */
		return 0;
	}
	else
	{
		/*
		 * Note: PG cursor is INSENSITIVE (=STATIC) cursor but its
		 * implemenation doesn't store the result into temporary storage other
		 * than T-SQL does. We don't know the # of rows. So return -1 here as
		 * same as DYNAMIC cursor does.
		 */
		return -1;
	}
}

static int
cursor_column_count_impl(const char *curname)
{
	Portal		portal;

	portal = SPI_cursor_find(curname);
	if (portal == NULL || portal->tupDesc == NULL)
	{
		/* cursor is not opened or already closed */
		return -1;
	}
	else
	{
		return portal->tupDesc->natts;
	}
}

/* Find all available cursors */
Datum
cursor_list(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	CursorHashEnt *hentry;
	HASH_SEQ_STATUS hash_seq;
	PLtsql_execstate *estate;
	int			cursor_scope_required;
	int			i;

	cursor_scope_required = PG_GETARG_INT32(0);
	if (cursor_scope_required < 1 || cursor_scope_required > 3)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("invalid cursor_scope: %d", cursor_scope_required)));

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/*
	 * build tupdesc for result tuples. This must match the definition of the
	 * sys.babelfish_cursor_list in sys_function_helpers.sql
	 */
	tupdesc = CreateTemplateTupleDesc(15);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "reference_name",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "cursor_name",
					   TEXTOID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "cursor_scope",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "status",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 5, "model",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 6, "concurrency",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 7, "scrollable",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 8, "open_status",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 9, "cursor_rows",
					   INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 10, "fetch_status",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 11, "column_count",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 12, "row_count",
					   INT8OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 13, "last_operation",
					   INT2OID, -1, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 14, "cursor_handle",
					   INT4OID, -1, 0);

	/*
	 * Hidden attributes used in sp_describe_cursor. Will not be projected to
	 * user.
	 */
	TupleDescInitEntry(tupdesc, (AttrNumber) 15, "cursor_source",
					   INT2OID, -1, 0);

	/*
	 * We put all the tuples into a tuplestore in one scan of the hashtable.
	 * This avoids any issue of the hashtable possibly changing between calls.
	 */
	tupstore =
		tuplestore_begin_heap(rsinfo->allowedModes & SFRM_Materialize_Random,
							  false, 1024);

	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	estate = get_current_tsql_estate();
	if (estate == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("cursor_list() cannot access execution state")));

	/* scan all the variables in top estate */
	for (i = 0; i < estate->ndatums; i++)
	{
		if (estate->datums[i]->dtype == PLTSQL_DTYPE_VAR)
		{
			PLtsql_var *var = (PLtsql_var *) estate->datums[i];

			if (is_cursor_datatype(var->datatype->typoid)
				&& !var->isnull
				&& !(var->cursor_options & PGTSQL_CURSOR_ANONYMOUS))
			{
				char	   *curname;
				Datum		values[15];
				bool		nulls[15];
				int			cursor_scope;

				MemSet(nulls, 0, sizeof(nulls));

				curname = TextDatumGetCString(var->value);
				hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);

				if (hentry == NULL) /* This can happen for PG internal cursor.
									 * skip it */
					continue;

				cursor_scope = 1;	/* cursor_scope: always LOCAL for now */

				if (!(cursor_scope & cursor_scope_required))
					continue;

				values[0] = CStringGetTextDatum(var->refname);
				values[1] = CStringGetTextDatum(pltsql_demangle_curname(curname));
				values[2] = cursor_scope;
				values[3] = cursor_status_impl(var);
				values[4] = 1;	/* model: always STATIC for now */
				values[5] = 1;	/* concurreny: always READ_ONLY for now */
				values[6] = (var->cursor_options & CURSOR_OPT_NO_SCROLL) ? 0 : 1;
				values[7] = (SPI_cursor_find(curname) == NULL) ? 0 : 1; /* open status */
				values[8] = cursor_rows_impl(curname);
				values[9] = hentry->fetch_status;
				values[10] = cursor_column_count_impl(curname);
				values[11] = hentry->row_count;
				values[12] = hentry->last_operation;
				values[13] = hentry->cursor_handle; /* cursor handle */
				values[14] = var->isconst ? values[2] : 3;	/* cursor source */

				tuplestore_putvalues(tupstore, tupdesc, values, nulls);
			}
		}
	}

	/* scan all hash entries to find api cursors */
	hash_seq_init(&hash_seq, CursorHashTable);

	while ((hentry = hash_seq_search(&hash_seq)) != NULL)
	{
		Datum		values[15];
		bool		nulls[15];
		int			cursor_scope;

		MemSet(nulls, 0, sizeof(nulls));

		cursor_scope = 2;		/* cursor_scope: always GLOBAL for api cursor */

		if (!(cursor_scope & cursor_scope_required))
			continue;

		if (!hentry->api_cursor)
			continue;

		values[0] = CStringGetTextDatum("NULL");	/* reference name */
		values[1] = CStringGetTextDatum("NULL");	/* cursor name. TODO:
													 * handle renaming via
													 * sp_cursoroption */
		values[2] = cursor_scope;
		values[3] = cursor_status_impl2(hentry->curname);
		values[4] = 1;			/* model: always STATIC for now */
		values[5] = 1;			/* concurreny: always READ_ONLY for now */
		values[6] = (hentry->cursor_options & CURSOR_OPT_NO_SCROLL) ? 0 : 1;
		values[7] = (SPI_cursor_find(hentry->curname) == NULL) ? 0 : 1; /* open status */
		values[8] = cursor_rows_impl(hentry->curname);
		values[9] = hentry->fetch_status;
		values[10] = cursor_column_count_impl(hentry->curname);
		values[11] = hentry->row_count;
		values[12] = hentry->last_operation;
		values[13] = hentry->cursor_handle; /* cursor handle */
		values[14] = cursor_scope;	/* cursor source */

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	return (Datum) 0;
}

Datum
init_tsql_cursor_hash_tab(PG_FUNCTION_ARGS)
{
	/* Skip to set up if already created */
	if (CursorHashTable != NULL)
		PG_RETURN_INT32(0);

	pltsql_create_cursor_htab();

	last_opened_cursor[0] = 0;

	PG_RETURN_INT32(0);
}

#define SP_CURSOR_OPTTYPE_UPDATE      0x0001
#define SP_CURSOR_OPTTYPE_DELETE      0x0002
#define SP_CURSOR_OPTTYPE_INSERT      0x0004
#define SP_CURSOR_OPTTYPE_REFRESH     0x0008
#define SP_CURSOR_OPTTYPE_LOCK        0x10
#define SP_CURSOR_OPTTYPE_SETPOSITION 0x20
#define SP_CURSOR_OPTTYPE_ABSOLUTE    0x40

#define SP_CURSOR_SCROLLOPT_KEYSET                  0x0001
#define SP_CURSOR_SCROLLOPT_DYNAMIC                 0x0002
#define SP_CURSOR_SCROLLOPT_FORWARD_ONLY            0x0004
#define SP_CURSOR_SCROLLOPT_STATIC                  0x0008
#define SP_CURSOR_SCROLLOPT_FAST_FORWARD            0x10
#define SP_CURSOR_SCROLLOPT_PARAMETERIZED_STMT      0x1000
#define SP_CURSOR_SCROLLOPT_AUTO_FETCH              0x2000
#define SP_CURSOR_SCROLLOPT_AUTO_CLOSE              0x4000
#define SP_CURSOR_SCROLLOPT_CHECK_ACCEPTED_TYPES    0x8000
#define SP_CURSOR_SCROLLOPT_KEYSET_ACCEPTABLE       0x10000
#define SP_CURSOR_SCROLLOPT_DYNAMIC_ACCEPTABLE      0x20000
#define SP_CURSOR_SCROLLOPT_FORWARD_ONLY_ACCEPTABLE 0x40000
#define SP_CURSOR_SCROLLOPT_STATIC_ACCEPTABLE       0x80000
#define SP_CURSOR_SCROLLOPT_FAST_FORWARD_ACCEPTABLE 0x100000

#define SP_CURSOR_CCOPT_READ_ONLY               0x0001
#define SP_CURSOR_CCOPT_SCROLL_LOCKS            0x0002	/* previously known as
														 * LOCKCC */
#define SP_CURSOR_CCOPT_OPTIMISTIC1             0x0004	/* previously known as
														 * OPTCC */
#define SP_CURSOR_CCOPT_OPTIMISTIC2             0x0008	/* previously known as
														 * OPTCCVAL */
#define SP_CURSOR_CCOPT_ALLOW_DIRECT            0x2000
#define SP_CURSOR_CCOPT_UPDT_IN_PLACE           0x4000
#define SP_CURSOR_CCOPT_CHECK_ACCEPTED_OPTS     0x8000
#define SP_CURSOR_CCOPT_READ_ONLY_ACCEPTABLE    0x10000
#define SP_CURSOR_CCOPT_SCROLL_LOCKS_ACCEPTABLE 0x20000
#define SP_CURSOR_CCOPT_OPTIMISTIC_ACCEPTABLE   0x40000
#define SP_CURSOR_CCOPT_OPTIMISITC_ACCEPTABLE   0x80000

#define SP_CURSOR_FETCH_FIRST          0x0001
#define SP_CURSOR_FETCH_NEXT           0x0002
#define SP_CURSOR_FETCH_PREV           0x0004
#define SP_CURSOR_FETCH_LAST           0x0008
#define SP_CURSOR_FETCH_ABSOLUTE       0x10
#define SP_CURSOR_FETCH_RELATIVE       0x20
#define SP_CURSOR_FETCH_REFRESH        0x80
#define SP_CURSOR_FETCH_INFO           0x100
#define SP_CURSOR_FETCH_PREV_NOADJUST  0x200
#define SP_CURSOR_FETCH_SKIP_UPDT_CNCY 0x400

#define SP_CURSOR_OPTION_CODE_TEXTPTR_ONLY 0x1
#define SP_CURSOR_OPTION_CODE_CURSOR_NAME  0x2
#define SP_CURSOR_OPTION_CODE_TEXTDATA     0x3
#define SP_CURSOR_OPTION_CODE_SCROLLOPT    0x4
#define SP_CURSOR_OPTION_CODE_CCOPT        0x5
#define SP_CURSOR_OPTION_CODE_ROWCOUNT     0x6


int
execute_sp_cursor(int cursor_handle, int opttype, int rownum, const char *tablename, List *values)
{
	int			rc;
	char		curname[NAMEDATALEN];
	CursorHashEnt *hentry;
	Portal		portal;
	DestReceiver *receiver;
	TupleTableSlot *slot;
	MemoryContext savedPortalCxt;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	validate_sp_cursor_params(opttype, rownum, tablename, values);

	snprintf(curname, NAMEDATALEN, "%d", cursor_handle);
	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
		elog(ERROR, "cursor \"%s\" does not exist", curname);

	if (opttype & SP_CURSOR_OPTTYPE_REFRESH)
	{
		if (hentry->fetch_buffer == NULL)
			elog(ERROR, "cursor \"%s\" has no fetch buffer", curname);

		portal = SPI_cursor_find(hentry->curname);

		receiver = CreateDestReceiver(DestRemote);
		SetRemoteDestReceiverParams(receiver, portal);

		tuplestore_rescan(hentry->fetch_buffer);
		slot = MakeSingleTupleTableSlot(hentry->tupdesc, &TTSOpsMinimalTuple);
		receiver->rStartup(receiver, (int) CMD_SELECT, hentry->tupdesc);
		while (tuplestore_gettupleslot(hentry->fetch_buffer, true, false, slot))
			receiver->receiveSlot(slot, receiver);
		receiver->rShutdown(receiver);
	}

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
}

int
execute_sp_cursoropen(int *cursor_handle, const char *stmt, int *pscrollopt, int *pccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls)
{
	return execute_sp_cursoropen_common(NULL, cursor_handle, stmt, pscrollopt, pccopt, row_count, nparams, nBindParams, boundParamsOidList, values, nulls, true /* prepare */ , false /* save_plan */ , true /* execute */ );
}

/* old interface to be compatabile with TDS */
int
execute_sp_cursoropen_old(int *cursor_handle, const char *stmt, int *pscrollopt, int *pccopt, int *row_count, int nparams, Datum *values, const char *nulls)
{
	return execute_sp_cursoropen_common(NULL, cursor_handle, stmt, pscrollopt, pccopt, row_count, nparams, 0, NULL, values, nulls, true /* prepare */ , false /* save_plan */ , true /* execute */ );
}

int
execute_sp_cursorprepare(int *stmt_handle, const char *stmt, int options, int *pscrollopt, int *pccopt, int nBindParams, Oid *boundParamsOidList)
{
	/* TODO: options handling */
	return execute_sp_cursoropen_common(stmt_handle, NULL, stmt, pscrollopt, pccopt, NULL, 0, nBindParams, boundParamsOidList, NULL, NULL, true /* prepare */ , true /* save_plan */ , false /* execute */ );
}

int
execute_sp_cursorexecute(int stmt_handle, int *cursor_handle, int *pscrollopt, int *pccopt, int *rowcount, int nparams, Datum *values, const char *nulls)
{
	return execute_sp_cursoropen_common(&stmt_handle, cursor_handle, NULL, pscrollopt, pccopt, rowcount, nparams, 0, NULL, values, nulls, false /* prepare */ , false /* save_plan */ , true /* execute */ );
}

int
execute_sp_cursorprepexec(int *stmt_handle, int *cursor_handle, const char *stmt, int options, int *pscrollopt, int *pccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls)
{
	return execute_sp_cursoropen_common(stmt_handle, cursor_handle, stmt, pscrollopt, pccopt, row_count, nparams, nBindParams, boundParamsOidList, values, nulls, true /* prepare */ , true /* save_plan */ , true /* execute */ );
}

int
execute_sp_cursorunprepare(int stmt_handle)
{
	int			rc;
	MemoryContext savedPortalCxt;
	CursorPreparedHandleHashEnt *phentry;
	bool		found;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	phentry = (CursorPreparedHandleHashEnt *) hash_search(CursorPreparedHandleHashTable, &stmt_handle, HASH_FIND, NULL);
	if (phentry == NULL)
		elog(ERROR, "can't find prepared handle: %u", stmt_handle);

	if (phentry->plan)
	{
		SPI_freeplan(phentry->plan);
		phentry->plan = NULL;
	}

	hash_search(CursorPreparedHandleHashTable, &stmt_handle, HASH_REMOVE, &found);
	Assert(found);

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
}

int
execute_sp_cursorfetch(int cursor_handle, int *pfetchtype, int *prownum, int *pnrows)
{
	int			rc;
	char		curname[NAMEDATALEN];
	CursorHashEnt *hentry;
	Portal		portal;
	int			fetchtype;
	int			rownum;
	int			nrows;
	DestReceiver *receiver;
	TupleTableSlot *slot;
	int			rno;
	MemoryContext oldcontext;
	MemoryContext savedPortalCxt;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	/* find cursor entry, validate input options and open portal */
	snprintf(curname, NAMEDATALEN, "%d", cursor_handle);
	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
		elog(ERROR, "cursor \"%s\" does not exist", curname);

	validate_and_get_sp_cursorfetch_params(pfetchtype, prownum, pnrows, &fetchtype, &rownum, &nrows);

	/* prepare fetch buffer if not exists */
	if (hentry->fetch_buffer == NULL)
	{
		oldcontext = MemoryContextSwitchTo(CursorHashtabContext);
		hentry->fetch_buffer = tuplestore_begin_heap(true, true, 1024);
		MemoryContextSwitchTo(oldcontext);
	}

	/* actual fetch */
	portal = SPI_cursor_find(hentry->curname);
	if (portal == NULL)
		elog(ERROR, "portal \"%s\" does not exist", hentry->curname);

	switch (fetchtype)
	{
		case SP_CURSOR_FETCH_FIRST:
			/* rewind to start */
			SPI_scroll_cursor_move(portal, FETCH_ABSOLUTE, 0);
			/* if needed, return some rows */
			if (nrows > 0)
				SPI_scroll_cursor_fetch_dest(portal, FETCH_FORWARD, nrows, CreateDestReceiver(DestSPI));
			break;
		case SP_CURSOR_FETCH_NEXT:
			Assert(nrows > 0);
			/* fetch in forward direction */
			SPI_scroll_cursor_fetch_dest(portal, FETCH_FORWARD, nrows, CreateDestReceiver(DestSPI));
			break;
		case SP_CURSOR_FETCH_PREV:
			Assert(nrows > 0);
			/* fetch in backward direction */
			SPI_scroll_cursor_fetch_dest(portal, FETCH_BACKWARD, nrows, CreateDestReceiver(DestSPI));
			break;
		case SP_CURSOR_FETCH_LAST:
			/* advance to end, back up abs(nrows)-1 rows */
			SPI_scroll_cursor_move(portal, FETCH_ABSOLUTE, -nrows - 1);
			/* if needed, return some rows */
			if (nrows > 0)
				SPI_scroll_cursor_fetch_dest(portal, FETCH_FORWARD, nrows, CreateDestReceiver(DestSPI));
			break;
		case SP_CURSOR_FETCH_ABSOLUTE:
			/* rewind to start, advance count-1 rows */
			SPI_scroll_cursor_move(portal, FETCH_ABSOLUTE, rownum - 1);
			Assert(nrows > 0);
			/* fetch in forward direction */
			SPI_scroll_cursor_fetch_dest(portal, FETCH_FORWARD, nrows, CreateDestReceiver(DestSPI));
			break;
		case SP_CURSOR_FETCH_RELATIVE:
		case SP_CURSOR_FETCH_REFRESH:
		case SP_CURSOR_FETCH_INFO:
		case SP_CURSOR_FETCH_PREV_NOADJUST:
		case SP_CURSOR_FETCH_SKIP_UPDT_CNCY:
		default:
			Assert(0);
	}

	if (SPI_result != 0)
		elog(ERROR, "error in SPI_scroll_cursor_fetch: %d", SPI_result);

	/*
	 * In case of FETCH_FIRST/FETCH_LAST with 0 nrows, we just moved cursor
	 * and no actual fetch is called. SPI_tuptable can be NULL. skip storing
	 * the result
	 */
	if (SPI_tuptable)
	{
		/* store result in fetch buffer */
		tuplestore_clear(hentry->fetch_buffer);

		oldcontext = MemoryContextSwitchTo(CursorHashtabContext);
		for (rno = 0; rno < SPI_processed; ++rno)
			tuplestore_puttuple(hentry->fetch_buffer, SPI_tuptable->vals[rno]);
		MemoryContextSwitchTo(oldcontext);

		tuplestore_rescan(hentry->fetch_buffer);

		/* send result to DestRemote */
		receiver = CreateDestReceiver(DestRemote);
		SetRemoteDestReceiverParams(receiver, portal);

		slot = MakeSingleTupleTableSlot(hentry->tupdesc, &TTSOpsMinimalTuple);
		receiver->rStartup(receiver, (int) CMD_SELECT, hentry->tupdesc);
		while (tuplestore_gettupleslot(hentry->fetch_buffer, true, false, slot))
			receiver->receiveSlot(slot, receiver);
		receiver->rShutdown(receiver);
	}

	/* update cursor status */
	pltsql_update_cursor_fetch_status(curname, SPI_processed == 0 ? -1 : 0);
	pltsql_update_cursor_row_count(curname, SPI_processed);
	pltsql_update_cursor_last_operation(curname, 2);

	/* If AUTO_CLOSE is set and we fetched all the result, close the cursor */
	if ((hentry->cursor_options & TSQL_CURSOR_OPT_AUTO_CLOSE) &&
		portal->atEnd)
	{
		execute_sp_cursorclose(cursor_handle);
	}

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
}

#define BITMAPSIZE(natts) (((natts-1)/8)+1)

int
execute_sp_cursoroption(int cursor_handle, int code, int value)
{
	int			rc;
	char		curname[NAMEDATALEN];
	CursorHashEnt *hentry;
	Portal		portal;
	MemoryContext oldcontext;
	MemoryContext savedPortalCxt;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	validate_sp_cursoroption_params(code, value);

	snprintf(curname, NAMEDATALEN, "%d", cursor_handle);
	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
		elog(ERROR, "cursor \"%s\" does not exist", curname);

	portal = SPI_cursor_find(hentry->curname);
	if (portal == NULL)
		elog(ERROR, "portal \"%s\" does not exist", hentry->curname);
	if (portal->tupDesc == NULL)
		elog(ERROR, "portal \"%s\" does not have tupeDesc", hentry->curname);

	switch (code)
	{
		case SP_CURSOR_OPTION_CODE_TEXTPTR_ONLY:
			{
				if (hentry->textptr_only_bitmap == NULL)
				{
					oldcontext = MemoryContextSwitchTo(CursorHashtabContext);
					hentry->textptr_only_bitmap = (char *) palloc0(BITMAPSIZE(portal->tupDesc->natts));
					MemoryContextSwitchTo(oldcontext);
				}

				if (value == 0) /* ALL */
				{
					memset(hentry->textptr_only_bitmap, 0xff, BITMAPSIZE(portal->tupDesc->natts));
				}
				else if (value > 0 && value <= portal->tupDesc->natts)
				{
					int			idx = value - 1;

					hentry->textptr_only_bitmap[idx / 8] |= (0x1 << (idx & 7));
				}
				else
					elog(ERROR, "cursoroption value %d is out of range", value);
				break;
			}
		case SP_CURSOR_OPTION_CODE_TEXTDATA:
			{
				if (hentry->textptr_only_bitmap == NULL)
				{
					oldcontext = MemoryContextSwitchTo(CursorHashtabContext);
					hentry->textptr_only_bitmap = (char *) palloc0(BITMAPSIZE(portal->tupDesc->natts));
					MemoryContextSwitchTo(oldcontext);
				}

				if (value == 0) /* ALL */
				{
					memset(hentry->textptr_only_bitmap, 0x00, BITMAPSIZE(portal->tupDesc->natts));
				}
				else if (value > 0 && value <= portal->tupDesc->natts)
				{
					int			idx = value - 1;

					hentry->textptr_only_bitmap[idx / 8] &= ~(0x1 << (idx & 7));
				}
				else
					elog(ERROR, "cursoroption value %d is out of range", value);
				break;
			}
		default:
			Assert(0);
	}

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
}

int
execute_sp_cursoroption2(int cursor_handle, int code, const char *value)
{
	/* TODO: handled along with updable cursor */
	return 0;
}

int
execute_sp_cursorclose(int cursor_handle)
{
	int			rc;
	char		curname[NAMEDATALEN];
	CursorHashEnt *hentry;
	Portal		portal;
	MemoryContext savedPortalCxt;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	snprintf(curname, NAMEDATALEN, "%d", cursor_handle);
	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
		elog(ERROR, "cursor \"%s\" does not exist", curname);

	portal = SPI_cursor_find(hentry->curname);
	if (portal == NULL)
		elog(ERROR, "portal \"%s\" does not exist", hentry->curname);

	if (IS_TDS_CLIENT() && portal->portalPinned)

		UnpinPortal(portal);

	SPI_cursor_close(portal);

	pltsql_update_cursor_row_count(curname, 0);
	pltsql_update_cursor_last_operation(curname, 6);

	pltsql_delete_cursor_entry(curname, false);

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
}

/*
 * sp_cursoropen: prepare + execute
 * sp_cursorprepare: prepare + save_plan
 * sp_cursorexecute: execute
 * sp_cursorprepexec: prepare + save_plan + exectue
 */
static int
execute_sp_cursoropen_common(int *stmt_handle, int *cursor_handle, const char *stmt, int *pscrollopt, int *pccopt, int *row_count, int nparams, int nBindParams, Oid *boundParamsOidList, Datum *values, const char *nulls, bool prepare, bool save_plan, bool execute)
{
	int			rc;
	int			scrollopt;
	int			ccopt;
	int			cursor_options;
	bool		found;
	SPIPlanPtr	plan;
	CursorPreparedHandleHashEnt *phentry;
	CursorHashEnt *hentry;
	Portal		portal;
	MemoryContext oldcontext;
	MemoryContext savedPortalCxt;

	/*
	 * Connect to SPI manager. should be handled in the same way with
	 * pltsql_inline_handler()
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	/* cursor options */
	scrollopt = (pscrollopt ? *pscrollopt : 0);
	ccopt = (pccopt ? *pccopt : 0);
	cursor_options = validate_and_get_sp_cursoropen_params(scrollopt, ccopt);

	if (prepare)
	{
		/* prepare plan and insert a cursor entry */
		plan = SPI_prepare_cursor(stmt, nBindParams, boundParamsOidList, cursor_options);
		if (plan == NULL)
			return 1;			/* procedure failed */

		if (save_plan)
		{
			*stmt_handle = get_next_cursor_prepared_handle();
			phentry = (CursorPreparedHandleHashEnt *) hash_search(CursorPreparedHandleHashTable, stmt_handle, HASH_ENTER, &found);
			Assert(!found);		/* already checked in
								 * get_next_cursor_prepared_handle() */

			phentry->handle = *stmt_handle;
			phentry->plan = plan;
			phentry->cursor_options = cursor_options;

			SPI_keepplan(plan);
		}
	}
	else						/* !prepare */
	{
		phentry = (CursorPreparedHandleHashEnt *) hash_search(CursorPreparedHandleHashTable, stmt_handle, HASH_FIND, NULL);
		if (phentry == NULL)
			elog(ERROR, "can't find stmt_handle: %u", *stmt_handle);
		if (phentry->plan == NULL)
			elog(ERROR, "can't find prepared plan for %u", *stmt_handle);

		plan = phentry->plan;
		cursor_options = phentry->cursor_options;
	}

	Assert(plan);

	if (execute)
	{
		bool		read_only;
		char		curname[NAMEDATALEN];
		bool		snapshot_pushed = false;

		if (SPI_getargcount(plan) != nparams)
			ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							errmsg("the numeber of arguments in plan mismatches with inputs")));

		read_only = (cursor_options & TSQL_CURSOR_OPT_READ_ONLY);

		*cursor_handle = get_next_cursor_handle();

		if (cursor_handle != NULL)
			snprintf(curname, NAMEDATALEN, "%d", *cursor_handle);

		/* add new cursor entry */
		hentry = pltsql_insert_cursor_entry(curname, NULL, cursor_options, cursor_handle);
		hentry->api_cursor = true;

		/* open cursor */
		PG_TRY();
		{
			if (read_only && !ActiveSnapshotSet())
			{
				/*
				 * Other than SPI_execute, SPI_cursor_open expects there is
				 * already an active snapshot in read-only mode. If
				 * sp_cursoropen is used in SQL batch, there maybe no active
				 * snapshot because we don't use normal PG path.
				 */
				PushActiveSnapshot(GetTransactionSnapshot());
				snapshot_pushed = true;
			}

			portal = SPI_cursor_open(hentry->curname, plan, values, nulls, read_only);
			if (portal == NULL)
				elog(ERROR, "could not open cursor: %s", SPI_result_code_string(SPI_result));

			oldcontext = MemoryContextSwitchTo(CursorHashtabContext);
			hentry->tupdesc = CreateTupleDescCopy(portal->tupDesc);
			MemoryContextSwitchTo(oldcontext);

			/*
			 * row_count can be ignored if AUTO_FETCH is not specified.
			 * Currently we don't support AUTO_FETCH so we do not need to
			 * handle row_count
			 */
			Assert(row_count == NULL || (scrollopt & SP_CURSOR_SCROLLOPT_AUTO_FETCH) == 0);
		}
		PG_CATCH();
		{
			pltsql_delete_cursor_entry(hentry->curname, true);
			if (snapshot_pushed)
				PopActiveSnapshot();
			if (!save_plan)
				SPI_freeplan(plan);

			PG_RE_THROW();
		}
		PG_END_TRY();

		pltsql_update_cursor_fetch_status(hentry->curname, 0);
		pltsql_update_cursor_last_operation(hentry->curname, 1);
		if (snapshot_pushed)
			PopActiveSnapshot();
	}

	if (prepare && !save_plan)
		SPI_freeplan(plan);

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	return 0;
	/* success */
}

static int
validate_and_get_sp_cursoropen_params(int scrollopt, int ccopt)
{
	int			curoptions = 0;

	/*
	 * As of now, only READ ONLY cursors are supported.  Scroll locks,
	 * optimistic and update-in-place cursors are not yet supported.
	 */
	if ((ccopt & SP_CURSOR_CCOPT_READ_ONLY) == 0)
	{
		/* check the accepted options */
		if (!(ccopt & SP_CURSOR_CCOPT_CHECK_ACCEPTED_OPTS))
			elog(ERROR, "only READ ONLY cursors are supported");

		if ((ccopt & SP_CURSOR_CCOPT_READ_ONLY) == 0)
			elog(ERROR, "only READ ONLY cursors are supported");
	}

	curoptions |= TSQL_CURSOR_OPT_READ_ONLY;

	/*
	 * Also, allow-direct cursors are not supported, but we'll allow it to be
	 * executed as normal cursor.  So, clear the flag unconditionally so that
	 * we can send the correct scrollopt OUT parameter value.
	 */
	scrollopt &= ~SP_CURSOR_CCOPT_ALLOW_DIRECT;

	if (scrollopt & SP_CURSOR_SCROLLOPT_AUTO_CLOSE)
	{
		if ((scrollopt & ~SP_CURSOR_SCROLLOPT_AUTO_CLOSE & ~SP_CURSOR_SCROLLOPT_FAST_FORWARD & ~SP_CURSOR_SCROLLOPT_FORWARD_ONLY) != 0)
			elog(ERROR, "cursor auto-close cannot be used with other SCROLLOPT options except FAST_FORWARD and FORWARD_ONLY");
	}

	if (scrollopt & SP_CURSOR_SCROLLOPT_AUTO_FETCH)
		elog(ERROR, "cursor auto-fetch is not yet implemented.");

	/* TODO: cursor sensitivity option handling */

	/*
	 * We're always going to fetch in binary format. Also, cursor opened via
	 * sp_cursoropen is global. We will set OPT_HOLD to make the portal
	 * accessible even if transaction is committed. Portal should be released
	 * via sp_cursorclose()
	 */
	curoptions = CURSOR_OPT_BINARY | CURSOR_OPT_HOLD;

	if (scrollopt & SP_CURSOR_SCROLLOPT_FORWARD_ONLY)
	{
		curoptions |= CURSOR_OPT_NO_SCROLL;
	}
	else if ((ccopt & SP_CURSOR_SCROLLOPT_CHECK_ACCEPTED_TYPES) &&
			 (ccopt & SP_CURSOR_SCROLLOPT_FORWARD_ONLY_ACCEPTABLE))
	{
		curoptions |= CURSOR_OPT_NO_SCROLL;
	}
	else
	{
		curoptions |= CURSOR_OPT_SCROLL;
	}

	if (scrollopt & SP_CURSOR_SCROLLOPT_AUTO_CLOSE)
	{
		curoptions |= TSQL_CURSOR_OPT_AUTO_CLOSE;
	}

	return curoptions;
}

static void
validate_sp_cursor_params(int opttype, int rownum, const char *tablename, List *values)
{
	if (opttype & SP_CURSOR_OPTTYPE_UPDATE)
		elog(ERROR, "sp_cursor UPDATE is not yet implmeneted.");

	if (opttype & SP_CURSOR_OPTTYPE_DELETE)
		elog(ERROR, "sp_cursor DELETE is not yet implmeneted.");

	if (opttype & SP_CURSOR_OPTTYPE_INSERT)
		elog(ERROR, "sp_cursor INSERT is not yet implmeneted.");

	if (opttype & SP_CURSOR_OPTTYPE_LOCK)
		elog(ERROR, "sp_cursor LOCK is not yet implmeneted.");

	if (opttype & SP_CURSOR_OPTTYPE_ABSOLUTE)
		elog(ERROR, "sp_cursor ABSOLUTE is not yet implmeneted.");
}

static void
validate_and_get_sp_cursorfetch_params(int *fetchtype_in, int *rownum_in, int *nrows_in, int *fetchtype_out, int *rownum_out, int *nrows_out)
{
	/* fetchtype */
	if (fetchtype_in != NULL)
	{
		switch (*fetchtype_in)
		{
			case SP_CURSOR_FETCH_FIRST:
			case SP_CURSOR_FETCH_NEXT:
			case SP_CURSOR_FETCH_PREV:
			case SP_CURSOR_FETCH_LAST:
			case SP_CURSOR_FETCH_ABSOLUTE:
				break;

				/*
				 * The following cursor options are not supported in postgres.
				 * Although postgres supports the relative cursor fetch
				 * option, but the behaviour in TDS protocol is very different
				 * from postgres.
				 */
			case SP_CURSOR_FETCH_RELATIVE:
			case SP_CURSOR_FETCH_REFRESH:
			case SP_CURSOR_FETCH_INFO:
			case SP_CURSOR_FETCH_PREV_NOADJUST:
			case SP_CURSOR_FETCH_SKIP_UPDT_CNCY:
				elog(ERROR, "cursor fetch type %X not supported", *fetchtype_in);
				elog(ERROR, "invalid cursor fetch type %X", *fetchtype_in);
				break;
			default:
				elog(ERROR, "invalid cursor fetch type %X", *fetchtype_in);
		}

		*fetchtype_out = *fetchtype_in;
	}
	else
	{
		*fetchtype_out = SP_CURSOR_FETCH_NEXT;
	}

	/* rownum */
	if (rownum_in != NULL)
	{
		/*
		 * Rownum is used to specify the row position for the ABSOLUTE and
		 * INFO fetchtype.  And, it serves as the row offset for the fetchtype
		 * bit value RELATIVE.  It is ignored for all other values.
		 */
		if (*fetchtype_in != SP_CURSOR_FETCH_ABSOLUTE &&
			*fetchtype_in != SP_CURSOR_FETCH_RELATIVE &&
			*fetchtype_in != SP_CURSOR_FETCH_INFO)
			*rownum_out = -1;
		else
			*rownum_out = *rownum_in;
	}
	else
	{
		*rownum_out = -1;
	}

	/* nrows */
	if (nrows_in != NULL)
	{
		/*
		 * For the fetchtype values of NEXT, PREV, ABSOLUTE, RELATIVE, and
		 * PREV_NOADJUST, an nrow value of 0 is not valid.
		 */
		if (*nrows_in == 0)
		{
			if (*fetchtype_in == SP_CURSOR_FETCH_NEXT ||
				*fetchtype_in == SP_CURSOR_FETCH_PREV ||
				*fetchtype_in == SP_CURSOR_FETCH_ABSOLUTE ||
				*fetchtype_in == SP_CURSOR_FETCH_RELATIVE ||
				*fetchtype_in == SP_CURSOR_FETCH_PREV_NOADJUST)
				elog(ERROR, "invalid nrow value 0 for cursor type %X", *fetchtype_in);
		}

		*nrows_out = *nrows_in;
	}
	else
	{
		/* If nrows is not specified, the default value is 20 rows. */
		*nrows_out = 20;
	}
}

static void
validate_sp_cursoroption_params(int code, int value)
{
	if ((code == SP_CURSOR_OPTION_CODE_SCROLLOPT) ||
		(code == SP_CURSOR_OPTION_CODE_CCOPT) ||
		(code == SP_CURSOR_OPTION_CODE_ROWCOUNT))
		elog(ERROR, "cursoroption code %X not supported", code);
}

Datum
pltsql_cursor_show_textptr_only_column_indexes(PG_FUNCTION_ARGS)
{
	uint32		cursor_handle;
	char		curname[NAMEDATALEN];
	CursorHashEnt *hentry;
	Portal		portal;
	StringInfoData buffer;
	int			i,
				j,
				k;

	cursor_handle = PG_GETARG_INT32(0);
	snprintf(curname, NAMEDATALEN, "%u", cursor_handle);

	hentry = (CursorHashEnt *) hash_search(CursorHashTable, curname, HASH_FIND, NULL);
	if (hentry == NULL)
	{
		elog(ERROR, "cursor_handle %u does not exist", cursor_handle);
	}

	if (hentry->textptr_only_bitmap == NULL)
	{
		PG_RETURN_TEXT_P(cstring_to_text(""));
	}

	portal = SPI_cursor_find(hentry->curname);
	if (portal == NULL)
		elog(ERROR, "portal \"%s\" does not exist", hentry->curname);
	if (portal->tupDesc == NULL)
		elog(ERROR, "portal \"%s\" does not have tupeDesc", hentry->curname);

	k = 1;
	initStringInfo(&buffer);
	for (i = 0; i < BITMAPSIZE(portal->tupDesc->natts); ++i)
	{
		for (j = 0; j < 8; ++j, k++)
		{
			if (hentry->textptr_only_bitmap[i] & (0x1 << j))
			{
				if (buffer.len == 0)
					appendStringInfo(&buffer, "%d", k);
				else
					appendStringInfo(&buffer, ", %d", k);
			}

			if (k >= portal->tupDesc->natts)
				break;
		}
	}

	PG_RETURN_TEXT_P(cstring_to_text(buffer.data));
}

Datum
pltsql_get_last_cursor_handle(PG_FUNCTION_ARGS)
{
	return current_cursor_handle;
}

Datum
pltsql_get_last_stmt_handle(PG_FUNCTION_ARGS)
{
	return current_cursor_prepared_handle;
}

/*
 * reset_cached_cursor:
 *		Cleans up all the stale cursor states and resets the cursor handles.
 *		This function should be called when a connection is cancelled or terminated.
 */
void
reset_cached_cursor(void)
{
	HASH_SEQ_STATUS hash_seq;
	CursorHashEnt *hentry;
	CursorPreparedHandleHashEnt *phentry;

	/* Iterate through the CursorHashTable and clean up each cursor. */
	hash_seq_init(&hash_seq, CursorHashTable);
	while ((hentry = (CursorHashEnt *) hash_seq_search(&hash_seq)) != NULL)
	{
		/* Clean up the cursor data. */
		if (hentry && hentry->tupdesc)
		{
			FreeTupleDesc(hentry->tupdesc);
			hentry->tupdesc = NULL;
		}
		if (hentry && hentry->fetch_buffer)
		{
			tuplestore_end(hentry->fetch_buffer);
			hentry->fetch_buffer = NULL;
		}
		if (hentry && hentry->textptr_only_bitmap)
		{
			pfree(hentry->textptr_only_bitmap);
			hentry->textptr_only_bitmap = NULL;
		}
	}

	/* Iterate through the CursorPreparedHandleHashTable and clean up each prepared cursor. */
	hash_seq_init(&hash_seq, CursorPreparedHandleHashTable);
	while ((phentry = (CursorPreparedHandleHashEnt *) hash_seq_search(&hash_seq)) != NULL)
	{
		if (phentry && phentry->plan)
		{
			SPI_freeplan(phentry->plan);
			phentry->plan = NULL;
		}
	}

	hash_destroy(CursorHashTable);
	hash_destroy(CursorPreparedHandleHashTable);
	CursorHashTable = NULL;
	CursorPreparedHandleHashTable = NULL;

	/* Re-create the cursor-related data structures. */
	pltsql_create_cursor_htab();
	/* Reset cursor handles. */
	current_cursor_handle = CURSOR_HANDLE_INVALID;
	current_cursor_prepared_handle = CURSOR_PREPARED_HANDLE_START;

	/* Reset sp_cursor_params. */
	reset_sp_cursor_params();
}