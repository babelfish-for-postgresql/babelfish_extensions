/*-------------------------------------------------------------------------
 *
 * adhoc_cache.c
 *    Persistent ANTLR parse tree cache for ad-hoc T-SQL queries.
 *
 * Implements:
 *   - Lexer-based T-SQL query normalization (literal replacement, whitespace
 *     collapse, case folding)
 *   - Hash-based cache key generation
 *   - Catalog table read/write/eviction operations
 *   - SQL-callable statistics and flush functions
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/genam.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/tableam.h"
#include "access/xact.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "executor/spi.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "common/hashfn.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/snapmgr.h"
#include "utils/timestamp.h"

#include "pltsql.h"
#include "catalog.h"
#include "adhoc_cache.h"
#include "babelfish_version.h"
#include "multidb.h"
#include "session.h"

PG_FUNCTION_INFO_V1(adhoc_antlr_parse_cache_stats);
PG_FUNCTION_INFO_V1(flush_adhoc_antlr_parse_cache);

/*****************************************
 *    GUC VARIABLES
 *****************************************/
bool	pltsql_enable_adhoc_antlr_parse_cache = false;
int		pltsql_adhoc_parse_cache_max_entries = 10000;
bool	pltsql_validate_adhoc_antlr_parse_cache = false;

/*****************************************
 *    STATISTICS COUNTERS
 *****************************************/
int pltsql_adhoc_cache_stat_hits = 0;
int pltsql_adhoc_cache_stat_misses = 0;
int pltsql_adhoc_cache_stat_writes = 0;
int pltsql_adhoc_cache_stat_evictions = 0;
int pltsql_adhoc_cache_stat_errors = 0;

/*****************************************
 *    PRIVATE VARIABLES
 *****************************************/
static Oid adhoc_parse_cache_oid = InvalidOid;
static Oid adhoc_parse_cache_idx_oid = InvalidOid;

/* ----------------------------------------------------------------
 * Query Normalization
 *
 * A simple lexer-based normalizer that:
 * 1. Replaces numeric literals with $N placeholders
 * 2. Replaces string literals with $N placeholders
 * 3. Collapses whitespace to single spaces
 * 4. Folds keywords/identifiers to lowercase
 * 5. Strips single-line (--) and block comments
 * 6. Strips trailing semicolons
 * ----------------------------------------------------------------
 */

/* States for the normalization lexer */
typedef enum NormLexState
{
	NORM_DEFAULT,
	NORM_IN_SINGLE_QUOTE,		/* inside '...' string */
	NORM_IN_LINE_COMMENT,		/* inside -- ... \n */
	NORM_IN_BLOCK_COMMENT,		/* inside / * ... * / */
	NORM_IN_NUMBER,				/* reading numeric literal */
	NORM_IN_IDENTIFIER,			/* reading identifier/keyword */
	NORM_IN_BRACKET_IDENT,		/* inside [...] delimited identifier */
	NORM_IN_DOUBLE_QUOTE		/* inside "..." quoted identifier */
} NormLexState;

/*
 * normalize_adhoc_query
 *
 * Normalize a T-SQL query for cache key generation. Replaces all constant
 * literals (integers, floats, strings) with positional parameters ($1, $2, ...),
 * folds unquoted text to lowercase, and collapses whitespace.
 *
 * Returns a palloc'd normalized string.
 */
char *
normalize_adhoc_query(const char *query_text)
{
	StringInfoData result;
	const char *p = query_text;
	int			param_num = 0;
	bool		last_was_space = false;
	NormLexState state = NORM_DEFAULT;

	initStringInfo(&result);

	while (*p != '\0')
	{
		switch (state)
		{
			case NORM_DEFAULT:
				if (*p == '-' && *(p + 1) == '-')
				{
					/* Single-line comment: skip until newline */
					state = NORM_IN_LINE_COMMENT;
					p += 2;
				}
				else if (*p == '/' && *(p + 1) == '*')
				{
					/* Block comment: skip until */ 
					state = NORM_IN_BLOCK_COMMENT;
					p += 2;
				}
				else if (*p == '\'')
				{
					/* String literal: replace with parameter */
					state = NORM_IN_SINGLE_QUOTE;
					param_num++;
					appendStringInfo(&result, "$%d", param_num);
					last_was_space = false;
					p++;
				}
				else if (*p == '[')
				{
					/* Bracketed identifier: preserve as-is but lowercase */
					state = NORM_IN_BRACKET_IDENT;
					appendStringInfoChar(&result, '[');
					last_was_space = false;
					p++;
				}
				else if (*p == '"')
				{
					/* Double-quoted identifier: preserve as-is */
					state = NORM_IN_DOUBLE_QUOTE;
					appendStringInfoChar(&result, '"');
					last_was_space = false;
					p++;
				}
				else if (isdigit((unsigned char) *p) ||
						 (*p == '.' && isdigit((unsigned char) *(p + 1))))
				{
					/*
					 * Numeric literal. Check if preceded by identifier char
					 * (in which case it's part of an identifier like "table1").
					 */
					if (result.len > 0 &&
						(isalnum((unsigned char) result.data[result.len - 1]) ||
						 result.data[result.len - 1] == '_' ||
						 result.data[result.len - 1] == '@' ||
						 result.data[result.len - 1] == '#'))
					{
						/* Part of identifier, emit as-is */
						appendStringInfoChar(&result, pg_tolower((unsigned char) *p));
						last_was_space = false;
						p++;
					}
					else
					{
						/* Standalone numeric literal: replace with parameter */
						state = NORM_IN_NUMBER;
						param_num++;
						appendStringInfo(&result, "$%d", param_num);
						last_was_space = false;
						p++;
					}
				}
				else if (*p == '0' && (*(p + 1) == 'x' || *(p + 1) == 'X'))
				{
					/* Hex literal: replace with parameter */
					param_num++;
					appendStringInfo(&result, "$%d", param_num);
					last_was_space = false;
					p += 2;
					/* Skip hex digits */
					while (isxdigit((unsigned char) *p))
						p++;
				}
				else if (isspace((unsigned char) *p))
				{
					/* Whitespace: collapse to single space */
					if (!last_was_space && result.len > 0)
					{
						appendStringInfoChar(&result, ' ');
						last_was_space = true;
					}
					p++;
				}
				else if (isalpha((unsigned char) *p) || *p == '_' ||
						 *p == '@' || *p == '#')
				{
					/* Identifier/keyword start: fold to lowercase */
					state = NORM_IN_IDENTIFIER;
					appendStringInfoChar(&result, pg_tolower((unsigned char) *p));
					last_was_space = false;
					p++;
				}
				else
				{
					/* Operators, punctuation: emit as-is */
					appendStringInfoChar(&result, *p);
					last_was_space = false;
					p++;
				}
				break;

			case NORM_IN_SINGLE_QUOTE:
				if (*p == '\'' && *(p + 1) == '\'')
				{
					/* Escaped single quote inside string: skip both */
					p += 2;
				}
				else if (*p == '\'')
				{
					/* End of string literal */
					state = NORM_DEFAULT;
					p++;
				}
				else
				{
					/* Inside string: skip */
					p++;
				}
				break;

			case NORM_IN_LINE_COMMENT:
				if (*p == '\n')
				{
					state = NORM_DEFAULT;
					/* Treat comment as whitespace */
					if (!last_was_space && result.len > 0)
					{
						appendStringInfoChar(&result, ' ');
						last_was_space = true;
					}
				}
				p++;
				break;

			case NORM_IN_BLOCK_COMMENT:
				if (*p == '*' && *(p + 1) == '/')
				{
					state = NORM_DEFAULT;
					p += 2;
					/* Treat comment as whitespace */
					if (!last_was_space && result.len > 0)
					{
						appendStringInfoChar(&result, ' ');
						last_was_space = true;
					}
				}
				else
				{
					p++;
				}
				break;

			case NORM_IN_NUMBER:
				if (isdigit((unsigned char) *p) || *p == '.' ||
					*p == 'e' || *p == 'E' ||
					((*p == '+' || *p == '-') &&
					 (*(p - 1) == 'e' || *(p - 1) == 'E')))
				{
					/* Still part of the number: skip */
					p++;
				}
				else
				{
					/* End of number */
					state = NORM_DEFAULT;
					/* Don't advance p — reprocess this char */
				}
				break;

			case NORM_IN_IDENTIFIER:
				if (isalnum((unsigned char) *p) || *p == '_' ||
					*p == '@' || *p == '#' || *p == '$')
				{
					appendStringInfoChar(&result, pg_tolower((unsigned char) *p));
					p++;
				}
				else
				{
					state = NORM_DEFAULT;
					/* Don't advance p — reprocess this char */
				}
				break;

			case NORM_IN_BRACKET_IDENT:
				if (*p == ']')
				{
					appendStringInfoChar(&result, ']');
					state = NORM_DEFAULT;
					p++;
				}
				else
				{
					/* Inside bracket: lowercase the content */
					appendStringInfoChar(&result, pg_tolower((unsigned char) *p));
					p++;
				}
				break;

			case NORM_IN_DOUBLE_QUOTE:
				if (*p == '"')
				{
					appendStringInfoChar(&result, '"');
					state = NORM_DEFAULT;
					p++;
				}
				else
				{
					appendStringInfoChar(&result, *p);
					p++;
				}
				break;
		}
	}

	/* Strip trailing whitespace and semicolons */
	while (result.len > 0 &&
		   (result.data[result.len - 1] == ' ' ||
			result.data[result.len - 1] == ';'))
	{
		result.data[--result.len] = '\0';
	}

	return result.data;
}

/* ----------------------------------------------------------------
 * Hash computation
 * ----------------------------------------------------------------
 */

/*
 * compute_adhoc_query_hash
 *
 * Compute a 64-bit hash of normalized query text using PostgreSQL's
 * hash_any_extended (Murmurhash).
 */
int64
compute_adhoc_query_hash(const char *normalized_text)
{
	uint64	hash;

	hash = DatumGetUInt64(hash_any_extended((const unsigned char *) normalized_text,
											strlen(normalized_text),
											0));
	return (int64) hash;
}

/* ----------------------------------------------------------------
 * Catalog table OID helpers
 * ----------------------------------------------------------------
 */

Oid
get_adhoc_parse_cache_oid(void)
{
	if (!OidIsValid(adhoc_parse_cache_oid))
		adhoc_parse_cache_oid = get_relname_relid(BBF_ADHOC_PARSE_CACHE_TABLE_NAME,
												  get_namespace_oid("sys", false));
	return adhoc_parse_cache_oid;
}

Oid
get_adhoc_parse_cache_idx_oid(void)
{
	if (!OidIsValid(adhoc_parse_cache_idx_oid))
		adhoc_parse_cache_idx_oid = get_relname_relid(BBF_ADHOC_PARSE_CACHE_IDX_NAME,
													  get_namespace_oid("sys", false));
	return adhoc_parse_cache_idx_oid;
}

/* ----------------------------------------------------------------
 * Cache Lookup
 * ----------------------------------------------------------------
 */

/*
 * lookup_adhoc_parse_cache
 *
 * Look up a cached parse tree entry by hash and db_id.
 * Performs collision detection by comparing stored normalized_query.
 * Returns NULL on miss or version mismatch.
 */
AdhocCacheEntry *
lookup_adhoc_parse_cache(int64 query_hash_id, int16 db_id,
						 const char *normalized_query)
{
	Relation	rel;
	ScanKeyData scankey[2];
	SysScanDesc scan;
	HeapTuple	tuple;
	AdhocCacheEntry *entry = NULL;
	Oid			cache_table_oid;
	Oid			cache_idx_oid;
	bool		isnull;
	bool		snapshot_pushed = false;

	cache_table_oid = get_adhoc_parse_cache_oid();
	if (!OidIsValid(cache_table_oid))
		return NULL;

	cache_idx_oid = get_adhoc_parse_cache_idx_oid();

	/* Ensure we have an active snapshot for the catalog scan */
	if (!ActiveSnapshotSet())
	{
		PushActiveSnapshot(GetTransactionSnapshot());
		snapshot_pushed = true;
	}

	rel = table_open(cache_table_oid, AccessShareLock);

	ScanKeyInit(&scankey[0],
				Anum_adhoc_cache_query_hash_id,
				BTEqualStrategyNumber, F_INT8EQ,
				Int64GetDatum(query_hash_id));
	ScanKeyInit(&scankey[1],
				Anum_adhoc_cache_db_id,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(db_id));

	scan = systable_beginscan(rel, cache_idx_oid, true,
							  NULL, 2, scankey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		Datum		datum;
		char	   *stored_normalized;
		char	   *stored_version;

		/* Check normalized query for collision detection */
		datum = heap_getattr(tuple, Anum_adhoc_cache_normalized_query,
							RelationGetDescr(rel), &isnull);
		if (isnull)
			goto done;

		stored_normalized = TextDatumGetCString(datum);

		if (strcmp(stored_normalized, normalized_query) != 0)
		{
			/* Hash collision — different query, treat as miss */
			pfree(stored_normalized);
			goto done;
		}
		pfree(stored_normalized);

		/* Check version for lazy invalidation */
		datum = heap_getattr(tuple, Anum_adhoc_cache_bbf_version,
							RelationGetDescr(rel), &isnull);
		if (isnull)
			goto done;

		stored_version = TextDatumGetCString(datum);
		if (strcmp(stored_version, BABELFISH_VERSION_STR) != 0)
		{
			/* Version mismatch — stale entry, treat as miss */
			pfree(stored_version);
			goto done;
		}
		pfree(stored_version);

		/* Valid cache hit — extract parse tree and datums */
		entry = (AdhocCacheEntry *) palloc0(sizeof(AdhocCacheEntry));
		entry->query_hash_id = query_hash_id;
		entry->db_id = db_id;

		datum = heap_getattr(tuple, Anum_adhoc_cache_parse_tree,
							RelationGetDescr(rel), &isnull);
		if (isnull)
		{
			pfree(entry);
			entry = NULL;
			goto done;
		}
		entry->parse_tree = TextDatumGetCString(datum);

		datum = heap_getattr(tuple, Anum_adhoc_cache_parse_datums,
							RelationGetDescr(rel), &isnull);
		entry->parse_datums = isnull ? NULL : TextDatumGetCString(datum);
	}

done:
	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	/*
	 * Update use_count and last_used_at on cache hit.
	 * Do this after releasing the read lock to avoid lock upgrade.
	 */
	if (entry != NULL)
	{
		Relation	upd_rel;
		SysScanDesc upd_scan;
		HeapTuple	upd_tuple;

		upd_rel = table_open(cache_table_oid, RowExclusiveLock);

		ScanKeyInit(&scankey[0],
					Anum_adhoc_cache_query_hash_id,
					BTEqualStrategyNumber, F_INT8EQ,
					Int64GetDatum(query_hash_id));
		ScanKeyInit(&scankey[1],
					Anum_adhoc_cache_db_id,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(db_id));

		upd_scan = systable_beginscan(upd_rel, cache_idx_oid, true,
									  NULL, 2, scankey);

		upd_tuple = systable_getnext(upd_scan);
		if (HeapTupleIsValid(upd_tuple))
		{
			Datum		upd_values[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
			bool		upd_nulls[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
			bool		upd_replaces[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
			HeapTuple	new_tuple;
			Datum		old_count;
			bool		count_isnull;

			memset(upd_values, 0, sizeof(upd_values));
			memset(upd_nulls, false, sizeof(upd_nulls));
			memset(upd_replaces, false, sizeof(upd_replaces));

			/* Increment use_count */
			old_count = heap_getattr(upd_tuple, Anum_adhoc_cache_use_count,
									 RelationGetDescr(upd_rel), &count_isnull);
			upd_values[Anum_adhoc_cache_use_count - 1] =
				Int64GetDatum(count_isnull ? 1 : DatumGetInt64(old_count) + 1);
			upd_replaces[Anum_adhoc_cache_use_count - 1] = true;

			/* Update last_used_at */
			upd_values[Anum_adhoc_cache_last_used_at - 1] =
				TimestampTzGetDatum(GetCurrentTimestamp());
			upd_replaces[Anum_adhoc_cache_last_used_at - 1] = true;

			new_tuple = heap_modify_tuple(upd_tuple, RelationGetDescr(upd_rel),
										  upd_values, upd_nulls, upd_replaces);
			CatalogTupleUpdate(upd_rel, &upd_tuple->t_self, new_tuple);
			heap_freetuple(new_tuple);
		}

		systable_endscan(upd_scan);
		table_close(upd_rel, RowExclusiveLock);
	}

	if (snapshot_pushed)
		PopActiveSnapshot();

	return entry;
}

/* ----------------------------------------------------------------
 * Cache Write
 * ----------------------------------------------------------------
 */

/*
 * insert_adhoc_parse_cache
 *
 * Insert or update a cache entry. Uses SPI for simplicity in the POC.
 * On conflict (same hash + db_id), updates the existing entry.
 */
void
insert_adhoc_parse_cache(int64 query_hash_id, int16 db_id,
						 const char *normalized_query,
						 const char *parse_tree_str,
						 const char *parse_datums_str)
{
	Relation	rel;
	Oid			cache_table_oid;
	Datum		values[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
	bool		nulls[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
	HeapTuple	tuple;
	ScanKeyData scankey[2];
	SysScanDesc scan;
	HeapTuple	existing;
	Oid			cache_idx_oid;
	TimestampTz	now_ts;

	cache_table_oid = get_adhoc_parse_cache_oid();
	if (!OidIsValid(cache_table_oid))
	{
		pltsql_adhoc_cache_stat_errors++;
		return;
	}

	cache_idx_oid = get_adhoc_parse_cache_idx_oid();
	now_ts = GetCurrentTimestamp();

	rel = table_open(cache_table_oid, RowExclusiveLock);

	/* Check if entry already exists (upsert logic) */
	ScanKeyInit(&scankey[0],
				Anum_adhoc_cache_query_hash_id,
				BTEqualStrategyNumber, F_INT8EQ,
				Int64GetDatum(query_hash_id));
	ScanKeyInit(&scankey[1],
				Anum_adhoc_cache_db_id,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(db_id));

	scan = systable_beginscan(rel, cache_idx_oid, true,
							  NULL, 2, scankey);

	existing = systable_getnext(scan);

	if (HeapTupleIsValid(existing))
	{
		/* Update existing entry */
		Datum		replace_values[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
		bool		replace_nulls[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
		bool		replace_replaces[BBF_ADHOC_PARSE_CACHE_NUM_COLS];
		HeapTuple	new_tuple;

		memset(replace_values, 0, sizeof(replace_values));
		memset(replace_nulls, false, sizeof(replace_nulls));
		memset(replace_replaces, false, sizeof(replace_replaces));

		replace_values[Anum_adhoc_cache_parse_tree - 1] = CStringGetTextDatum(parse_tree_str);
		replace_replaces[Anum_adhoc_cache_parse_tree - 1] = true;

		if (parse_datums_str)
		{
			replace_values[Anum_adhoc_cache_parse_datums - 1] = CStringGetTextDatum(parse_datums_str);
			replace_nulls[Anum_adhoc_cache_parse_datums - 1] = false;
		}
		else
		{
			replace_nulls[Anum_adhoc_cache_parse_datums - 1] = true;
		}
		replace_replaces[Anum_adhoc_cache_parse_datums - 1] = true;

		replace_values[Anum_adhoc_cache_bbf_version - 1] = CStringGetTextDatum(BABELFISH_VERSION_STR);
		replace_replaces[Anum_adhoc_cache_bbf_version - 1] = true;

		replace_values[Anum_adhoc_cache_last_used_at - 1] = TimestampTzGetDatum(now_ts);
		replace_replaces[Anum_adhoc_cache_last_used_at - 1] = true;

		replace_values[Anum_adhoc_cache_use_count - 1] = Int64GetDatum(1);
		replace_replaces[Anum_adhoc_cache_use_count - 1] = true;

		new_tuple = heap_modify_tuple(existing, RelationGetDescr(rel),
									  replace_values, replace_nulls, replace_replaces);
		CatalogTupleUpdate(rel, &existing->t_self, new_tuple);
		heap_freetuple(new_tuple);
	}
	else
	{
		/* Insert new entry */
		memset(values, 0, sizeof(values));
		memset(nulls, false, sizeof(nulls));

		values[Anum_adhoc_cache_query_hash_id - 1] = Int64GetDatum(query_hash_id);
		values[Anum_adhoc_cache_db_id - 1] = Int16GetDatum(db_id);
		values[Anum_adhoc_cache_normalized_query - 1] = CStringGetTextDatum(normalized_query);
		values[Anum_adhoc_cache_parse_tree - 1] = CStringGetTextDatum(parse_tree_str);

		if (parse_datums_str)
			values[Anum_adhoc_cache_parse_datums - 1] = CStringGetTextDatum(parse_datums_str);
		else
			nulls[Anum_adhoc_cache_parse_datums - 1] = true;

		values[Anum_adhoc_cache_bbf_version - 1] = CStringGetTextDatum(BABELFISH_VERSION_STR);
		values[Anum_adhoc_cache_created_at - 1] = TimestampTzGetDatum(now_ts);
		values[Anum_adhoc_cache_last_used_at - 1] = TimestampTzGetDatum(now_ts);
		values[Anum_adhoc_cache_use_count - 1] = Int64GetDatum(1);

		tuple = heap_form_tuple(RelationGetDescr(rel), values, nulls);
		CatalogTupleInsert(rel, tuple);
		heap_freetuple(tuple);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	pltsql_adhoc_cache_stat_writes++;
}

/* ----------------------------------------------------------------
 * Cache Eviction
 * ----------------------------------------------------------------
 */

/*
 * evict_adhoc_parse_cache_if_needed
 *
 * If the cache has exceeded max_entries, evict the bottom 10% by last_used_at.
 * Uses SPI for the DELETE with ORDER BY/LIMIT.
 */
void
evict_adhoc_parse_cache_if_needed(void)
{
	int		ret;
	int		evict_count;
	char	query[256];

	if (pltsql_adhoc_parse_cache_max_entries <= 0)
		return;

	evict_count = pltsql_adhoc_parse_cache_max_entries / 10;
	if (evict_count < 1)
		evict_count = 1;

	/*
	 * Use SPI to delete oldest entries. This is called after a cache write
	 * so we're already in a transaction context.
	 */
	ret = SPI_connect();
	if (ret != SPI_OK_CONNECT)
	{
		pltsql_adhoc_cache_stat_errors++;
		return;
	}

	/* Check current count */
	ret = SPI_execute("SELECT count(*) FROM sys.babelfish_adhoc_parse_cache", true, 0);
	if (ret == SPI_OK_SELECT && SPI_processed > 0)
	{
		bool	isnull;
		int64	current_count;

		current_count = DatumGetInt64(SPI_getbinval(SPI_tuptable->vals[0],
													SPI_tuptable->tupdesc,
													1, &isnull));
		if (!isnull && current_count > pltsql_adhoc_parse_cache_max_entries)
		{
			snprintf(query, sizeof(query),
					 "DELETE FROM sys.babelfish_adhoc_parse_cache "
					 "WHERE ctid IN ("
					 "  SELECT ctid FROM sys.babelfish_adhoc_parse_cache "
					 "  ORDER BY last_used_at ASC LIMIT %d"
					 ")", evict_count);

			ret = SPI_execute(query, false, 0);
			if (ret == SPI_OK_DELETE)
				pltsql_adhoc_cache_stat_evictions += SPI_processed;
		}
	}

	SPI_finish();
}

/* ----------------------------------------------------------------
 * Cache Flush
 * ----------------------------------------------------------------
 */

void
flush_adhoc_parse_cache(void)
{
	int		ret;

	ret = SPI_connect();
	if (ret != SPI_OK_CONNECT)
		return;

	SPI_execute("TRUNCATE sys.babelfish_adhoc_parse_cache", false, 0);
	SPI_finish();
}

/* ----------------------------------------------------------------
 * SQL-callable Functions
 * ----------------------------------------------------------------
 */

/*
 * sys.adhoc_antlr_parse_cache_stats()
 *
 * Returns session-level statistics for the adhoc parse cache.
 */
Datum
adhoc_antlr_parse_cache_stats(PG_FUNCTION_ARGS)
{
	TupleDesc	tupdesc;
	Datum		values[6];
	bool		nulls[6] = {false};
	HeapTuple	tuple;

	/* Build tuple descriptor */
	if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("function returning record called in context "
						"that cannot accept type record")));

	tupdesc = BlessTupleDesc(tupdesc);

	values[0] = Int32GetDatum(pltsql_adhoc_cache_stat_hits);
	values[1] = Int32GetDatum(pltsql_adhoc_cache_stat_misses);
	values[2] = Int32GetDatum(pltsql_adhoc_cache_stat_writes);
	values[3] = Int32GetDatum(pltsql_adhoc_cache_stat_evictions);
	values[4] = Int32GetDatum(pltsql_adhoc_cache_stat_errors);

	/* Get current entry count via SPI */
	{
		int		ret;
		int64	count = 0;

		ret = SPI_connect();
		if (ret == SPI_OK_CONNECT)
		{
			ret = SPI_execute("SELECT count(*) FROM sys.babelfish_adhoc_parse_cache", true, 0);
			if (ret == SPI_OK_SELECT && SPI_processed > 0)
			{
				bool isnull;
				count = DatumGetInt64(SPI_getbinval(SPI_tuptable->vals[0],
												   SPI_tuptable->tupdesc,
												   1, &isnull));
			}
			SPI_finish();
		}
		values[5] = Int32GetDatum((int32) count);
	}

	tuple = heap_form_tuple(tupdesc, values, nulls);
	PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}

/*
 * sys.flush_adhoc_antlr_parse_cache()
 *
 * Flush all entries from the adhoc parse cache.
 */
Datum
flush_adhoc_antlr_parse_cache(PG_FUNCTION_ARGS)
{
	flush_adhoc_parse_cache();
	PG_RETURN_VOID();
}
