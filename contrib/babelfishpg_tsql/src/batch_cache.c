/*-------------------------------------------------------------------------
 *
 * batch_cache.c
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * Each entry stores the query text, serialized tree, and serialized datums
 * in fixed-size buffers. Eviction is LRU: drop the oldest 10% (min 5).
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "common/hashfn.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "storage/ipc.h"
#include "storage/lwlock.h"
#include "storage/shmem.h"
#include "utils/builtins.h"
#include "utils/acl.h"
#include "utils/guc_tables.h"
#include "utils/memutils.h"
#include "utils/timestamp.h"

#include "pltsql.h"
#include "guc.h"
#include "batch_cache.h"
#include "babelfish_version.h"

/* Defined in guc.c; not in guc.h for C/C++ linkage reasons (see guc.h) */
extern bool pltsql_quoted_identifier;
extern bool pltsql_allow_antlr_to_unsupported_grammar_for_testing;

PG_FUNCTION_INFO_V1(batch_antlr_parse_cache_stats);
PG_FUNCTION_INFO_V1(flush_batch_antlr_parse_cache);
PG_FUNCTION_INFO_V1(batch_antlr_parse_cache_entries);

/*****************************************
 *    EVICTION CONSTANTS
 *****************************************/
#define BATCH_CACHE_DEALLOC_PERCENT		10	/* free this % of entries at once */
#define BATCH_CACHE_MIN_VICTIMS			5	/* minimum entries to evict */

/*****************************************
 *    SHARED STATE (pointers into shmem)
 *****************************************/
static BatchCacheSharedState *batch_cache_state = NULL;
static HTAB *batch_cache_hash = NULL;


/* ----------------------------------------------------------------
 * Shared Memory Startup
 *
 * Attach to the state and hash created by babelfishpg_tds. Idempotent.
 * ----------------------------------------------------------------
 */
void
batch_cache_shmem_startup(void)
{
	bool		found_state;
	HASHCTL		info;
	BatchCacheSharedState *state;

	if (batch_cache_hash != NULL)
		return;					/* Already attached */

	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);

	state = ShmemInitStruct("batch_antlr_parse_cache_state",
							sizeof(BatchCacheSharedState),
							&found_state);

	/* Not created by babelfishpg_tds: leave the cache disabled */
	if (!found_state)
	{
		LWLockRelease(AddinShmemInitLock);
		ereport(LOG,
				(errmsg("batch query parse cache is disabled because its shared memory was not initialized")));
		return;
	}

	memset(&info, 0, sizeof(info));
	info.keysize = sizeof(BatchCacheKey);
	info.entrysize = sizeof(BatchCacheEntry);
	batch_cache_hash = ShmemInitHash("batch_antlr_parse_cache_hash",
									 BATCH_CACHE_DEFAULT_MAX_ENTRIES,
									 BATCH_CACHE_DEFAULT_MAX_ENTRIES,
									 &info,
									 HASH_ELEM | HASH_BLOBS);
	batch_cache_state = state;

	LWLockRelease(AddinShmemInitLock);
}

/* ----------------------------------------------------------------
 * Parameter Signature
 *
 * Parameter count, names, types, and modes change the ANTLR output (dno
 * layout, assignment casts). Typmod is excluded: parameters are built
 * with typmod -1, so it never reaches ANTLR.
 * ----------------------------------------------------------------
 */
uint64
compute_batch_cache_param_sig(int numargs, const Oid *argtypes,
							  const char *argmodes,
							  char **argnames)
{
	uint64		sig = (uint64) numargs;
	int			i;

	for (i = 0; i < numargs; i++)
	{
		sig = hash_combine64(sig, (uint64) (argtypes ? argtypes[i] : InvalidOid));
		sig = hash_combine64(sig, (uint64) (unsigned char) (argmodes ? argmodes[i] : 'i'));
		if (argnames && argnames[i])
			sig = hash_combine64(sig,
								 DatumGetUInt64(hash_any_extended((const unsigned char *) argnames[i],
																  strlen(argnames[i]),
																  0)));
		else
			sig = hash_combine64(sig, 0);
	}

	return sig;
}

/* ----------------------------------------------------------------
 * Parse-Context Signature
 *
 * Session settings read during the ANTLR parse that change the tree:
 * QUOTED_IDENTIFIER, enable_tsql_information_schema, enable_hint_mapping,
 * the test-grammar setting, and every escape hatch (found by name).
 * Add any new parse-time setting here.
 * ----------------------------------------------------------------
 */
#define BATCH_CACHE_ESCAPE_HATCH_PREFIX "babelfishpg_tsql.escape_hatch_"

static int **escape_hatch_vars = NULL;	/* pointers to escape hatch values */
static int	num_escape_hatch_vars = -1; /* -1 until first lookup */

static void
collect_escape_hatch_vars(void)
{
	struct config_generic **guc_vars;
	int			num_vars;
	int			i;
	size_t		prefix_len = strlen(BATCH_CACHE_ESCAPE_HATCH_PREFIX);

	guc_vars = get_guc_variables(&num_vars);
	escape_hatch_vars = (int **) MemoryContextAllocZero(TopMemoryContext,
														sizeof(int *) * Max(num_vars, 1));
	num_escape_hatch_vars = 0;

	for (i = 0; i < num_vars; i++)
	{
		struct config_generic *gconf = guc_vars[i];

		if (gconf->vartype == PGC_ENUM &&
			strncmp(gconf->name, BATCH_CACHE_ESCAPE_HATCH_PREFIX, prefix_len) == 0)
			escape_hatch_vars[num_escape_hatch_vars++] =
				((struct config_enum *) gconf)->variable;
	}

	pfree(guc_vars);			/* palloc'd by get_guc_variables() */
}

uint64
compute_batch_cache_parse_ctx_sig(void)
{
	uint64		sig = 0;
	int			i;

	if (num_escape_hatch_vars < 0)
		collect_escape_hatch_vars();

	sig = hash_combine64(sig, (uint64) pltsql_quoted_identifier);
	sig = hash_combine64(sig, (uint64) pltsql_enable_tsql_information_schema);
	sig = hash_combine64(sig, (uint64) enable_hint_mapping);
	sig = hash_combine64(sig, (uint64) pltsql_allow_antlr_to_unsupported_grammar_for_testing);

	for (i = 0; i < num_escape_hatch_vars; i++)
		sig = hash_combine64(sig, (uint64) (uint32) *escape_hatch_vars[i]);

	return sig;
}

/* Parameter signature combined with parse-context signature */
uint64
compute_batch_cache_compile_sig(int numargs, const Oid *argtypes,
								const char *argmodes, char **argnames)
{
	return hash_combine64(compute_batch_cache_param_sig(numargs, argtypes,
														argmodes, argnames),
						  compute_batch_cache_parse_ctx_sig());
}

/* Cache key: hash of query text, db_id, and compile signature */
BatchCacheKey
compute_batch_cache_key(const char *query_text, int16 db_id, uint64 compile_sig)
{
	uint64		hash;

	hash = DatumGetUInt64(hash_any_extended((const unsigned char *) query_text,
											strlen(query_text),
											0));
	hash = hash_combine64(hash, (uint64) db_id);
	hash = hash_combine64(hash, compile_sig);
	return (BatchCacheKey) hash;
}

/* ----------------------------------------------------------------
 * Cache Lookup
 *
 * Return palloc'd copies of the entry, made under the shared lock, or
 * NULL on miss. Any mismatch in text, compile signature, datum count, or
 * version is a miss. Caller frees the result.
 * ----------------------------------------------------------------
 */
BatchCacheLookupResult *
batch_cache_lookup(BatchCacheKey cache_key, const char *query_text,
				   uint64 compile_sig, int pre_cache_nDatums)
{
	BatchCacheEntry *entry;
	BatchCacheLookupResult *result;
	TimestampTz now;

	if (batch_cache_hash == NULL || batch_cache_state == NULL)
		return NULL;

	LWLockAcquire(batch_cache_state->lock, LW_SHARED);

	entry = (BatchCacheEntry *) hash_search(batch_cache_hash,
											&cache_key, HASH_FIND, NULL);

	if (entry == NULL ||
		entry->query_text_len != (int) strlen(query_text) ||
		strncmp(entry->query_text, query_text, entry->query_text_len) != 0 ||
		entry->compile_sig != compile_sig ||
		entry->pre_cache_nDatums != pre_cache_nDatums ||
		strcmp(entry->bbf_version, BABELFISH_VERSION_STR) != 0 ||
		entry->parse_tree_len <= 0)
	{
		pg_atomic_add_fetch_u64(&batch_cache_state->stat_misses, 1);
		LWLockRelease(batch_cache_state->lock);
		return NULL;
	}

	/* Copy under the lock so a concurrent eviction cannot overwrite it */
	result = (BatchCacheLookupResult *) palloc(sizeof(BatchCacheLookupResult));

	result->parse_tree_len = entry->parse_tree_len;
	result->parse_tree = palloc(entry->parse_tree_len + 1);
	memcpy(result->parse_tree, entry->parse_tree, entry->parse_tree_len);
	result->parse_tree[entry->parse_tree_len] = '\0';
	result->pre_cache_nDatums = entry->pre_cache_nDatums;

	if (entry->parse_datums_len > 0)
	{
		result->parse_datums_len = entry->parse_datums_len;
		result->parse_datums = palloc(entry->parse_datums_len + 1);
		memcpy(result->parse_datums, entry->parse_datums, entry->parse_datums_len);
		result->parse_datums[entry->parse_datums_len] = '\0';
	}
	else
	{
		result->parse_datums = NULL;
		result->parse_datums_len = 0;
	}

	/* Read the clock outside the spinlock */
	now = GetCurrentTimestamp();
	SpinLockAcquire(&entry->mutex);
	entry->last_used_at = now;
	SpinLockRelease(&entry->mutex);

	pg_atomic_add_fetch_u64(&batch_cache_state->stat_hits, 1);

	LWLockRelease(batch_cache_state->lock);

	return result;
}

/* Eviction order: oldest last_used_at first */
static int
batch_cache_entry_cmp(const void *a, const void *b)
{
	TimestampTz ts_a = (*(BatchCacheEntry **) a)->last_used_at;
	TimestampTz ts_b = (*(BatchCacheEntry **) b)->last_used_at;

	if (ts_a < ts_b)
		return -1;
	if (ts_a > ts_b)
		return 1;
	return 0;
}

/* ----------------------------------------------------------------
 * Cache Insert
 *
 * Copy the data into the entry, evicting first if the cache is full.
 * Returns false if the entry was skipped.
 * ----------------------------------------------------------------
 */
bool
batch_cache_insert(BatchCacheKey cache_key,
				   const char *query_text,
				   const char *parse_tree_str,
				   const char *parse_datums_str,
				   uint64 compile_sig,
				   int pre_cache_nDatums)
{
	BatchCacheEntry *entry;
	BatchCacheEntry **entries_arr;
	bool		found;
	int			query_len;
	int			tree_len;
	int			datums_len;

	if (batch_cache_hash == NULL || batch_cache_state == NULL)
		return false;

	query_len = strlen(query_text);
	tree_len = strlen(parse_tree_str);
	datums_len = parse_datums_str ? strlen(parse_datums_str) : 0;

	/* Check per-field buffer limits */
	if (query_len >= BATCH_CACHE_MAX_QUERY_TEXT_LEN ||
		tree_len >= BATCH_CACHE_MAX_PARSE_TREE_LEN ||
		datums_len >= BATCH_CACHE_MAX_PARSE_DATUMS_LEN)
	{
		elog(DEBUG1, "batch_parse_cache: entry exceeds buffer limit (query=%d tree=%d datums=%d), skipping",
			 query_len, tree_len, datums_len);
		return false;
	}

	/* Check min/max entry size GUCs (sizes are in KB) */
	{
		int			total_data_len = query_len + tree_len + datums_len;
		int			min_bytes = pltsql_batch_query_cache_min_entry_size * 1024;
		int			max_bytes = pltsql_batch_query_cache_max_entry_size * 1024;

		if (total_data_len < min_bytes)
		{
			elog(DEBUG1, "batch_parse_cache: entry too small (%d bytes, min %d bytes), skipping",
				 total_data_len, min_bytes);
			return false;
		}

		if (max_bytes > 0 && total_data_len > max_bytes)
		{
			elog(DEBUG1, "batch_parse_cache: entry too large (%d bytes, max %d bytes), skipping",
				 total_data_len, max_bytes);
			return false;
		}
	}

	/*
	 * Allocate before locking: nothing may raise an ERROR under the lock,
	 * since the caller's FlushErrorState() does not release LWLocks.
	 */
	entries_arr = (BatchCacheEntry **)
		palloc(sizeof(BatchCacheEntry *) * BATCH_CACHE_DEFAULT_MAX_ENTRIES);

	LWLockAcquire(batch_cache_state->lock, LW_EXCLUSIVE);

	entry = (BatchCacheEntry *) hash_search(batch_cache_hash,
											&cache_key, HASH_FIND, NULL);
	found = (entry != NULL);

	/* Key already used by different text or signature */
	if (found &&
		(entry->query_text_len != query_len ||
		 strncmp(entry->query_text, query_text, query_len) != 0 ||
		 entry->compile_sig != compile_sig))
	{
		pg_atomic_add_fetch_u64(&batch_cache_state->stat_errors, 1);
		LWLockRelease(batch_cache_state->lock);
		pfree(entries_arr);
		ereport(LOG,
				(errmsg("Hash collision in batch query parse cache"),
				 errdetail("Cache Key: %lu",
						   (unsigned long) cache_key)));
		return false;
	}

	if (!found)
	{
		/* Full: evict the least recently used 10% (min 5) */
		if (hash_get_num_entries(batch_cache_hash) >= (long) pltsql_batch_query_cache_max_entries)
		{
			HASH_SEQ_STATUS scan;
			BatchCacheEntry *scan_entry;
			long		num_entries = 0;
			long		num_to_drop;
			long		i;

			hash_seq_init(&scan, batch_cache_hash);
			while ((scan_entry = (BatchCacheEntry *) hash_seq_search(&scan)) != NULL)
			{
				if (num_entries < BATCH_CACHE_DEFAULT_MAX_ENTRIES)
					entries_arr[num_entries++] = scan_entry;
			}

			qsort(entries_arr, num_entries, sizeof(BatchCacheEntry *),
				  batch_cache_entry_cmp);

			num_to_drop = Max(BATCH_CACHE_MIN_VICTIMS, num_entries * BATCH_CACHE_DEALLOC_PERCENT / 100);
			num_to_drop = Min(num_to_drop, num_entries);

			for (i = 0; i < num_to_drop; i++)
			{
				hash_search(batch_cache_hash, &entries_arr[i]->key,
							HASH_REMOVE, NULL);
				pg_atomic_add_fetch_u64(&batch_cache_state->stat_evictions, 1);
			}
		}

		/* HASH_ENTER_NULL: returns NULL instead of raising ERROR */
		entry = (BatchCacheEntry *) hash_search(batch_cache_hash,
												&cache_key, HASH_ENTER_NULL, &found);
		if (entry == NULL)
		{
			pg_atomic_add_fetch_u64(&batch_cache_state->stat_errors, 1);
			LWLockRelease(batch_cache_state->lock);
			pfree(entries_arr);
			return false;
		}
	}

	memcpy(entry->query_text, query_text, query_len);
	entry->query_text[query_len] = '\0';
	entry->query_text_len = query_len;

	memcpy(entry->parse_tree, parse_tree_str, tree_len);
	entry->parse_tree[tree_len] = '\0';
	entry->parse_tree_len = tree_len;

	if (datums_len > 0)
	{
		memcpy(entry->parse_datums, parse_datums_str, datums_len);
		entry->parse_datums[datums_len] = '\0';
	}
	else
		entry->parse_datums[0] = '\0';
	entry->parse_datums_len = datums_len;

	strlcpy(entry->bbf_version, BABELFISH_VERSION_STR, sizeof(entry->bbf_version));
	entry->compile_sig = compile_sig;
	entry->pre_cache_nDatums = pre_cache_nDatums;
	entry->last_used_at = GetCurrentTimestamp();

	if (!found)
	{
		entry->created_at = entry->last_used_at;
		SpinLockInit(&entry->mutex);
	}

	pg_atomic_add_fetch_u64(&batch_cache_state->stat_writes, 1);

	LWLockRelease(batch_cache_state->lock);
	pfree(entries_arr);
	return true;
}

/* ----------------------------------------------------------------
 * Cache Flush
 * ----------------------------------------------------------------
 */
int64
batch_cache_flush(void)
{
	HASH_SEQ_STATUS scan;
	BatchCacheEntry *entry;
	int64		flushed = 0;

	if (batch_cache_hash == NULL || batch_cache_state == NULL)
		return 0;

	LWLockAcquire(batch_cache_state->lock, LW_EXCLUSIVE);

	hash_seq_init(&scan, batch_cache_hash);
	while ((entry = (BatchCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		hash_search(batch_cache_hash, &entry->key, HASH_REMOVE, NULL);
		flushed++;
	}

	/* Reset all stat counters */
	pg_atomic_write_u64(&batch_cache_state->stat_hits, 0);
	pg_atomic_write_u64(&batch_cache_state->stat_misses, 0);
	pg_atomic_write_u64(&batch_cache_state->stat_writes, 0);
	pg_atomic_write_u64(&batch_cache_state->stat_evictions, 0);
	pg_atomic_write_u64(&batch_cache_state->stat_errors, 0);

	LWLockRelease(batch_cache_state->lock);

	return flushed;
}

/* ----------------------------------------------------------------
 * SQL-callable Functions
 * ----------------------------------------------------------------
 */

Datum
batch_antlr_parse_cache_stats(PG_FUNCTION_ARGS)
{
	TupleDesc	tupdesc;
	Datum		values[6];
	bool		nulls[6] = {false};
	HeapTuple	tuple;

	/* Only sysadmin can access cache functions */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Only sysadmin can access batch query parse cache functions.")));

	if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("function returning record called in context "
						"that cannot accept type record")));

	tupdesc = BlessTupleDesc(tupdesc);

	if (batch_cache_state != NULL && batch_cache_hash != NULL)
	{
		values[0] = Int64GetDatum((int64) pg_atomic_read_u64(&batch_cache_state->stat_hits));
		values[1] = Int64GetDatum((int64) pg_atomic_read_u64(&batch_cache_state->stat_misses));
		values[2] = Int64GetDatum((int64) pg_atomic_read_u64(&batch_cache_state->stat_writes));
		values[3] = Int64GetDatum((int64) pg_atomic_read_u64(&batch_cache_state->stat_evictions));
		values[4] = Int64GetDatum((int64) pg_atomic_read_u64(&batch_cache_state->stat_errors));
		values[5] = Int64GetDatum(hash_get_num_entries(batch_cache_hash));
	}
	else
	{
		/* Shared memory not initialized */
		memset(values, 0, sizeof(values));
	}

	tuple = heap_form_tuple(tupdesc, values, nulls);
	PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}

Datum
flush_batch_antlr_parse_cache(PG_FUNCTION_ARGS)
{
	int64		flushed;

	/* Only sysadmin can access cache functions */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Only sysadmin can access batch query parse cache functions.")));

	flushed = batch_cache_flush();
	PG_RETURN_BOOL(flushed > 0);
}

/* Return one row per cache entry */
Datum
batch_antlr_parse_cache_entries(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	HASH_SEQ_STATUS scan;
	BatchCacheEntry *entry;

	/* Only sysadmin can access cache functions */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Only sysadmin can access batch query parse cache functions.")));

#define BATCH_CACHE_ENTRIES_COLS 9

	/* Check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	/* Build tupdesc for result tuples */
	if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("return type must be a row type")));

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	MemoryContextSwitchTo(oldcontext);

	/* If shared memory not initialized, return empty set */
	if (batch_cache_hash == NULL || batch_cache_state == NULL)
		return (Datum) 0;

	LWLockAcquire(batch_cache_state->lock, LW_SHARED);

	hash_seq_init(&scan, batch_cache_hash);
	while ((entry = (BatchCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		Datum		values[BATCH_CACHE_ENTRIES_COLS];
		bool		nulls[BATCH_CACHE_ENTRIES_COLS];

		memset(nulls, 0, sizeof(nulls));

		values[0] = UInt64GetDatum(entry->key);
		values[1] = TimestampTzGetDatum(entry->created_at);
		values[2] = TimestampTzGetDatum(entry->last_used_at);
		values[3] = Int32GetDatum(entry->query_text_len);
		values[4] = Int32GetDatum(entry->parse_tree_len);
		values[5] = Int32GetDatum(entry->parse_datums_len);
		values[6] = CStringGetTextDatum(entry->bbf_version);
		values[7] = CStringGetTextDatum(entry->query_text);
		values[8] = CStringGetTextDatum(entry->parse_tree);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	LWLockRelease(batch_cache_state->lock);

	return (Datum) 0;
}
