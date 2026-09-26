/*-------------------------------------------------------------------------
 *
 * batch_cache.c
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * All data (query text, serialized parse tree, datums) is embedded
 * directly in fixed-size buffers within each shared memory hash entry.
 * No external file, no disk I/O.
 *
 * Query text is stored for hash collision detection (strcmp on every
 * lookup). It is not exposed to customers via SQL functions.
 *
 * Eviction uses LRU: sort by last_used_at, drop bottom 10% (min 5).
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
#include "utils/timestamp.h"

#include "pltsql.h"
#include "guc.h"
#include "batch_cache.h"
#include "babelfish_version.h"

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
 * Shared Memory Request (called from shmem_request_hook)
 * ----------------------------------------------------------------
 */
void
batch_cache_shmem_request(void)
{
	/* Shmem is requested by babelfishpg_tds in tds.c */
}

/* ----------------------------------------------------------------
 * Shared Memory Startup (called from shmem_startup_hook)
 * ----------------------------------------------------------------
 */
void
batch_cache_shmem_startup(void)
{
	bool	found_state;
	HASHCTL	info;

	if (batch_cache_hash != NULL)
		return;		/* Already attached */

	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);

	/* Attach to shared state (created by babelfishpg_tds at startup) */
	batch_cache_state = ShmemInitStruct("batch_antlr_parse_cache_state",
										sizeof(BatchCacheSharedState),
										&found_state);

	/* Attach to shared hash table (created by babelfishpg_tds at startup) */
	memset(&info, 0, sizeof(info));
	info.keysize = sizeof(BatchCacheKey);
	info.entrysize = sizeof(BatchCacheEntry);
	batch_cache_hash = ShmemInitHash("batch_antlr_parse_cache_hash",
									 100, 100,
									 &info,
									 HASH_ELEM | HASH_BLOBS);

	LWLockRelease(AddinShmemInitLock);
}

/* ----------------------------------------------------------------
 * Cache Key Computation
 *
 * Combines query text hash and db_id into a single 64-bit key.
 * Same pattern as APG SPC's compute_aspc_id().
 * ----------------------------------------------------------------
 */
BatchCacheKey
compute_batch_cache_key(const char *query_text, int16 db_id)
{
	uint64	hash;

	hash = DatumGetUInt64(hash_any_extended((const unsigned char *) query_text,
											strlen(query_text),
											0));
	hash = hash_combine64(hash, (uint64) db_id);
	return (BatchCacheKey) hash;
}

/* ----------------------------------------------------------------
 * Cache Lookup
 *
 * Returns pointer to the entry if found and valid, NULL otherwise.
 * Collision detection: strcmp of query text on every hit.
 * ----------------------------------------------------------------
 */
BatchCacheEntry *
batch_cache_lookup(BatchCacheKey cache_key, const char *query_text)
{
	BatchCacheEntry *entry;

	if (batch_cache_hash == NULL || batch_cache_state == NULL)
		return NULL;

	LWLockAcquire(batch_cache_state->lock, LW_SHARED);

	entry = (BatchCacheEntry *) hash_search(batch_cache_hash,
											&cache_key, HASH_FIND, NULL);

	if (entry == NULL)
	{
		SpinLockAcquire(&batch_cache_state->mutex);
		batch_cache_state->stat_misses++;
		SpinLockRelease(&batch_cache_state->mutex);
		LWLockRelease(batch_cache_state->lock);
		return NULL;
	}

	/* Collision detection: compare stored query text */
	if (entry->query_text_len != (int) strlen(query_text) ||
		strncmp(entry->query_text, query_text, entry->query_text_len) != 0)
	{
		SpinLockAcquire(&batch_cache_state->mutex);
		batch_cache_state->stat_misses++;
		SpinLockRelease(&batch_cache_state->mutex);
		LWLockRelease(batch_cache_state->lock);
		return NULL;
	}

	/* Version check */
	if (strcmp(entry->bbf_version, BABELFISH_VERSION_STR) != 0)
	{
		SpinLockAcquire(&batch_cache_state->mutex);
		batch_cache_state->stat_misses++;
		SpinLockRelease(&batch_cache_state->mutex);
		LWLockRelease(batch_cache_state->lock);
		return NULL;
	}

	/*
	 * Valid hit — update last_used_at via per-entry spinlock for LRU
	 * tracking. Stay in shared lock mode so other backends can do lookups
	 * concurrently.
	 */
	SpinLockAcquire(&entry->mutex);
	entry->last_used_at = GetCurrentTimestamp();
	SpinLockRelease(&entry->mutex);

	/* Update global hit counter via shared state spinlock */
	SpinLockAcquire(&batch_cache_state->mutex);
	batch_cache_state->stat_hits++;
	SpinLockRelease(&batch_cache_state->mutex);

	LWLockRelease(batch_cache_state->lock);

	return entry;
}

/* ----------------------------------------------------------------
 * Eviction comparison function
 *
 * Sort entries by last_used_at ascending — oldest hit first (eviction
 * candidates). LRU policy.
 * ----------------------------------------------------------------
 */
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
 * Copies data directly into embedded buffers in the hash entry.
 * Handles eviction if needed.
 * Returns true on success, false on error (e.g. data too large).
 * ----------------------------------------------------------------
 */
bool
batch_cache_insert(BatchCacheKey cache_key,
				   const char *query_text,
				   const char *parse_tree_str,
				   const char *parse_datums_str)
{
	BatchCacheEntry *entry;
	bool	found;
	int		query_len;
	int		tree_len;
	int		datums_len;

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
		int		total_data_len = query_len + tree_len + datums_len;
		int		min_bytes = pltsql_batch_query_cache_min_entry_size * 1024;
		int		max_bytes = pltsql_batch_query_cache_max_entry_size * 1024;

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

	LWLockAcquire(batch_cache_state->lock, LW_EXCLUSIVE);

	/* Evict if at capacity — LRU: sort by last_used_at, drop bottom 10% */
	if (hash_get_num_entries(batch_cache_hash) >= (long) pltsql_batch_query_cache_max_entries)
	{
		HASH_SEQ_STATUS scan;
		BatchCacheEntry *scan_entry;
		BatchCacheEntry **entries_arr;
		long	num_entries;
		long	num_to_drop;
		long	i;

		num_entries = hash_get_num_entries(batch_cache_hash);

		/* Collect all entries into sortable array */
		entries_arr = palloc(sizeof(BatchCacheEntry *) * num_entries);
		i = 0;
		hash_seq_init(&scan, batch_cache_hash);
		while ((scan_entry = (BatchCacheEntry *) hash_seq_search(&scan)) != NULL)
		{
			if (i < num_entries)
				entries_arr[i++] = scan_entry;
		}
		num_entries = i;	/* actual count */

		/* Sort by last_used_at ascending (oldest hit first = LRU victims) */
		qsort(entries_arr, num_entries, sizeof(BatchCacheEntry *),
			  batch_cache_entry_cmp);

		/* Drop bottom BATCH_CACHE_DEALLOC_PERCENT%, minimum BATCH_CACHE_MIN_VICTIMS */
		num_to_drop = Max(BATCH_CACHE_MIN_VICTIMS, num_entries * BATCH_CACHE_DEALLOC_PERCENT / 100);
		num_to_drop = Min(num_to_drop, num_entries);

		for (i = 0; i < num_to_drop; i++)
		{
			hash_search(batch_cache_hash, &entries_arr[i]->key,
						HASH_REMOVE, NULL);
			batch_cache_state->stat_evictions++;
		}

		pfree(entries_arr);
	}

	/* Insert or find existing hash entry */
	entry = (BatchCacheEntry *) hash_search(batch_cache_hash,
											&cache_key, HASH_ENTER, &found);

	if (entry == NULL)
	{
		batch_cache_state->stat_errors++;
		LWLockRelease(batch_cache_state->lock);
		return false;
	}

	/* Hash collision check: if entry exists with different query text, skip */
	if (found &&
		(entry->query_text_len != query_len ||
		 strncmp(entry->query_text, query_text, query_len) != 0))
	{
		ereport(LOG,
				(errmsg("Hash collision in batch query parse cache"),
				 errdetail("Cache Key: %lu",
						   (unsigned long) cache_key)));
		batch_cache_state->stat_errors++;
		LWLockRelease(batch_cache_state->lock);
		return false;
	}

	/* Copy data into separate buffers */
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
	entry->last_used_at = GetCurrentTimestamp();

	if (!found)
	{
		entry->created_at = entry->last_used_at;
		SpinLockInit(&entry->mutex);
	}

	batch_cache_state->stat_writes++;

	LWLockRelease(batch_cache_state->lock);
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
	SpinLockAcquire(&batch_cache_state->mutex);
	batch_cache_state->stat_hits = 0;
	batch_cache_state->stat_misses = 0;
	batch_cache_state->stat_writes = 0;
	batch_cache_state->stat_evictions = 0;
	batch_cache_state->stat_errors = 0;
	SpinLockRelease(&batch_cache_state->mutex);

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

	if (get_call_result_type(fcinfo, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("function returning record called in context "
						"that cannot accept type record")));

	tupdesc = BlessTupleDesc(tupdesc);

	if (batch_cache_state != NULL && batch_cache_hash != NULL)
	{
		LWLockAcquire(batch_cache_state->lock, LW_SHARED);
		values[0] = Int64GetDatum(batch_cache_state->stat_hits);
		values[1] = Int64GetDatum(batch_cache_state->stat_misses);
		values[2] = Int64GetDatum(batch_cache_state->stat_writes);
		values[3] = Int64GetDatum(batch_cache_state->stat_evictions);
		values[4] = Int64GetDatum(batch_cache_state->stat_errors);
		values[5] = Int64GetDatum(hash_get_num_entries(batch_cache_hash));
		LWLockRelease(batch_cache_state->lock);
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
	int64	flushed = batch_cache_flush();
	PG_RETURN_BOOL(flushed > 0);
}

/*
 * batch_antlr_parse_cache_entries
 *
 * Set-returning function that exposes all entries in the cache.
 */
Datum
batch_antlr_parse_cache_entries(PG_FUNCTION_ARGS)
{
	ReturnSetInfo  *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc		tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext	per_query_ctx;
	MemoryContext	oldcontext;
	HASH_SEQ_STATUS scan;
	BatchCacheEntry *entry;

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
