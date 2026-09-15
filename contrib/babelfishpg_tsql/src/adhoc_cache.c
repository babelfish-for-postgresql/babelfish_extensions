/*-------------------------------------------------------------------------
 *
 * adhoc_cache.c
 *    Shared memory based ANTLR parse tree cache for ad-hoc T-SQL queries.
 *
 * Implements a shared memory hash table (ShmemInitHash) that stores
 * serialized ANTLR parse trees keyed by query hash + database ID.
 * All backends share the same cache, providing cross-session reuse
 * without disk I/O. Cache is lost on server restart.
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
#include "adhoc_cache.h"
#include "babelfish_version.h"

PG_FUNCTION_INFO_V1(adhoc_antlr_parse_cache_stats);
PG_FUNCTION_INFO_V1(flush_adhoc_antlr_parse_cache);

/*****************************************
 *    GUC VARIABLES
 *****************************************/
bool	pltsql_enable_adhoc_antlr_parse_cache = false;
int		pltsql_adhoc_parse_cache_max_entries = 1000;
bool	pltsql_validate_adhoc_antlr_parse_cache = false;

/*****************************************
 *    SHARED STATE (pointers into shmem)
 *****************************************/
static AdhocCacheSharedState *adhoc_cache_state = NULL;
static HTAB *adhoc_cache_hash = NULL;


/* ----------------------------------------------------------------
 * Shared Memory Request (called from shmem_request_hook)
 * ----------------------------------------------------------------
 */
void
adhoc_cache_shmem_request(void)
{
	/* No shared memory needed — using backend-local hash table */
}

/* ----------------------------------------------------------------
 * Shared Memory Startup (called from shmem_startup_hook)
 * ----------------------------------------------------------------
 */
void
adhoc_cache_shmem_startup(void)
{
	bool	found;
	HASHCTL	info;

	if (adhoc_cache_hash != NULL)
		return;		/* Already attached */

	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);

	/* Attach to shared state (created by babelfishpg_tds at startup) */
	adhoc_cache_state = ShmemInitStruct("adhoc_antlr_parse_cache_state",
										sizeof(AdhocCacheSharedState),
										&found);

	/* Attach to shared hash table (created by babelfishpg_tds at startup) */
	memset(&info, 0, sizeof(info));
	info.keysize = sizeof(AdhocCacheKey);
	info.entrysize = sizeof(AdhocCacheEntry);
	adhoc_cache_hash = ShmemInitHash("adhoc_antlr_parse_cache_hash",
									 100, 100,
									 &info,
									 HASH_ELEM | HASH_BLOBS);

	LWLockRelease(AddinShmemInitLock);
}

/* ----------------------------------------------------------------
 * Hash Computation
 * ----------------------------------------------------------------
 */
int64
compute_adhoc_query_hash(const char *query_text)
{
	uint64	hash;

	hash = DatumGetUInt64(hash_any_extended((const unsigned char *) query_text,
											strlen(query_text),
											0));
	return (int64) hash;
}

/* ----------------------------------------------------------------
 * Cache Lookup
 *
 * Returns pointer to the entry if found and valid, NULL otherwise.
 * Caller must hold or acquire no lock — this function handles locking.
 * ----------------------------------------------------------------
 */
AdhocCacheEntry *
adhoc_cache_lookup(int64 query_hash_id, int16 db_id,
				   const char *query_text)
{
	AdhocCacheKey key;
	AdhocCacheEntry *entry;

	if (adhoc_cache_hash == NULL || adhoc_cache_state == NULL)
		return NULL;

	/* Build lookup key */
	memset(&key, 0, sizeof(key));
	key.query_hash_id = query_hash_id;
	key.db_id = db_id;

	LWLockAcquire(adhoc_cache_state->lock, LW_SHARED);

	entry = (AdhocCacheEntry *) hash_search(adhoc_cache_hash,
											&key, HASH_FIND, NULL);

	if (entry == NULL)
	{
		LWLockRelease(adhoc_cache_state->lock);
		return NULL;
	}

	/* Collision detection: compare stored query text */
	if (entry->query_text_len != (int) strlen(query_text) ||
		strncmp(entry->query_text, query_text, entry->query_text_len) != 0)
	{
		/* Hash collision — different query */
		LWLockRelease(adhoc_cache_state->lock);
		return NULL;
	}

	/* Version check */
	if (strcmp(entry->bbf_version, BABELFISH_VERSION_STR) != 0)
	{
		/* Stale entry — version mismatch */
		LWLockRelease(adhoc_cache_state->lock);
		return NULL;
	}

	/* Valid hit — update stats (upgrade to exclusive for the update) */
	LWLockRelease(adhoc_cache_state->lock);
	LWLockAcquire(adhoc_cache_state->lock, LW_EXCLUSIVE);

	/* Re-find entry (could have been evicted between lock release/acquire) */
	entry = (AdhocCacheEntry *) hash_search(adhoc_cache_hash,
											&key, HASH_FIND, NULL);
	if (entry != NULL)
	{
		entry->use_count++;
		entry->last_used_at = GetCurrentTimestamp();
		adhoc_cache_state->stat_hits++;
	}

	LWLockRelease(adhoc_cache_state->lock);

	return entry;
}

/* ----------------------------------------------------------------
 * Cache Insert
 *
 * Insert a new entry or update existing one. Handles eviction if
 * the cache is full.
 * Returns true on success, false if the entry was too large to store.
 * ----------------------------------------------------------------
 */
bool
adhoc_cache_insert(int64 query_hash_id, int16 db_id,
				   const char *query_text,
				   const char *parse_tree_str,
				   const char *parse_datums_str)
{
	AdhocCacheKey key;
	AdhocCacheEntry *entry;
	bool	found;
	int		query_len;
	int		tree_len;
	int		datums_len;

	if (adhoc_cache_hash == NULL || adhoc_cache_state == NULL)
		return false;

	/* Check size limits */
	query_len = strlen(query_text);
	tree_len = strlen(parse_tree_str);
	datums_len = parse_datums_str ? strlen(parse_datums_str) : 0;

	if (query_len >= ADHOC_CACHE_MAX_QUERY_LEN ||
		tree_len >= ADHOC_CACHE_MAX_TREE_LEN ||
		datums_len >= ADHOC_CACHE_MAX_DATUMS_LEN)
	{
		/* Entry too large to store in fixed-size shmem buffer */
		adhoc_cache_state->stat_errors++;
		return false;
	}

	/* Build key */
	memset(&key, 0, sizeof(key));
	key.query_hash_id = query_hash_id;
	key.db_id = db_id;

	LWLockAcquire(adhoc_cache_state->lock, LW_EXCLUSIVE);

	/* Evict if at capacity */
	if (adhoc_cache_state->total_entries >= pltsql_adhoc_parse_cache_max_entries)
	{
		/* Simple eviction: find and remove the oldest entry (lowest use_count) */
		HASH_SEQ_STATUS scan;
		AdhocCacheEntry *oldest = NULL;
		AdhocCacheEntry *scan_entry;

		hash_seq_init(&scan, adhoc_cache_hash);
		while ((scan_entry = (AdhocCacheEntry *) hash_seq_search(&scan)) != NULL)
		{
			if (oldest == NULL || scan_entry->last_used_at < oldest->last_used_at)
				oldest = scan_entry;
		}

		if (oldest != NULL)
		{
			hash_search(adhoc_cache_hash, &oldest->key, HASH_REMOVE, NULL);
			adhoc_cache_state->total_entries--;
			adhoc_cache_state->stat_evictions++;
		}
	}

	/* Insert or update */
	entry = (AdhocCacheEntry *) hash_search(adhoc_cache_hash,
											&key, HASH_ENTER, &found);

	if (entry == NULL)
	{
		/* Should not happen with fixed-size table, but be safe */
		
		return false;
	}

	/* Fill entry */
	memcpy(entry->query_text, query_text, query_len);
	entry->query_text[query_len] = '\0';
	entry->query_text_len = query_len;

	memcpy(entry->parse_tree, parse_tree_str, tree_len);
	entry->parse_tree[tree_len] = '\0';
	entry->parse_tree_len = tree_len;

	if (parse_datums_str && datums_len > 0)
	{
		memcpy(entry->parse_datums, parse_datums_str, datums_len);
		entry->parse_datums[datums_len] = '\0';
		entry->parse_datums_len = datums_len;
	}
	else
	{
		entry->parse_datums[0] = '\0';
		entry->parse_datums_len = 0;
	}

	strlcpy(entry->bbf_version, BABELFISH_VERSION_STR, sizeof(entry->bbf_version));
	entry->use_count = 1;
	entry->last_used_at = GetCurrentTimestamp();

	if (!found)
	{
		entry->created_at = entry->last_used_at;
		adhoc_cache_state->total_entries++;
	}

	adhoc_cache_state->stat_writes++;

	LWLockRelease(adhoc_cache_state->lock);
	return true;
}

/* ----------------------------------------------------------------
 * Cache Flush
 * ----------------------------------------------------------------
 */
void
adhoc_cache_flush(void)
{
	HASH_SEQ_STATUS scan;
	AdhocCacheEntry *entry;

	if (adhoc_cache_hash == NULL || adhoc_cache_state == NULL)
		return;

	LWLockAcquire(adhoc_cache_state->lock, LW_EXCLUSIVE);

	hash_seq_init(&scan, adhoc_cache_hash);
	while ((entry = (AdhocCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		hash_search(adhoc_cache_hash, &entry->key, HASH_REMOVE, NULL);
	}

	adhoc_cache_state->total_entries = 0;

	LWLockRelease(adhoc_cache_state->lock);
}

/* ----------------------------------------------------------------
 * SQL-callable Functions
 * ----------------------------------------------------------------
 */

Datum
adhoc_antlr_parse_cache_stats(PG_FUNCTION_ARGS)
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

	if (adhoc_cache_state != NULL)
	{
		LWLockAcquire(adhoc_cache_state->lock, LW_SHARED);
		values[0] = Int64GetDatum(adhoc_cache_state->stat_hits);
		values[1] = Int64GetDatum(adhoc_cache_state->stat_misses);
		values[2] = Int64GetDatum(adhoc_cache_state->stat_writes);
		values[3] = Int64GetDatum(adhoc_cache_state->stat_evictions);
		values[4] = Int64GetDatum(adhoc_cache_state->stat_errors);
		values[5] = Int64GetDatum(adhoc_cache_state->total_entries);
		LWLockRelease(adhoc_cache_state->lock);
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
flush_adhoc_antlr_parse_cache(PG_FUNCTION_ARGS)
{
	adhoc_cache_flush();
	PG_RETURN_VOID();
}
