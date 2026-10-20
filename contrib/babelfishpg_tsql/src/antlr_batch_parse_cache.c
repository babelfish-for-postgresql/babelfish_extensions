/*-------------------------------------------------------------------------
 *
 * antlr_batch_parse_cache.c
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * Each entry stores the query text, serialized tree, and serialized datums
 * in fixed-size buffers. Eviction is LRU: drop the oldest 10% (min 5).
 *
 * The file is layered:
 *   1. Shared memory hash table management: find, enter, remove, evict,
 *      and entry-level helpers. Callers hold antlr_batch_parse_cache_state->lock.
 *   2. Cache get / put / flush: take the lock and use the layer-1 helpers.
 *   3. Parse cache: restore a cached tree and datums for
 *      pltsql_compile_inline(), or run ANTLR and store the result.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_type.h"
#include "common/hashfn.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "portability/instr_time.h"
#include "storage/ipc.h"
#include "storage/lwlock.h"
#include "storage/shmem.h"
#include "utils/builtins.h"
#include "utils/acl.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/syscache.h"
#include "utils/timestamp.h"

#include "pltsql.h"
#include "guc.h"
#include "session.h"
#include "antlr_batch_parse_cache.h"
#include "babelfish_version.h"
#include "pltsql_node/pltsql_serialize.h"

/* Defined in guc.c; not in guc.h for C/C++ linkage reasons (see guc.h) */
extern bool babelfish_dump_restore;

/* Defined in iterative_exec.c; reported by EXPLAIN */
extern instr_time antlr_parse_time;

PG_FUNCTION_INFO_V1(antlr_batch_parse_cache_stats);
PG_FUNCTION_INFO_V1(flush_antlr_batch_parse_cache);
PG_FUNCTION_INFO_V1(antlr_batch_parse_cache_entries);

/*****************************************
 *    EVICTION CONSTANTS
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_DEALLOC_PERCENT		10	/* free this % of
														 * entries at once */
#define ANTLR_BATCH_PARSE_CACHE_MIN_VICTIMS			5	/* minimum entries to
														 * evict */

/*****************************************
 *    SHARED STATE (pointers into shmem)
 *****************************************/
static AntlrBatchParseCacheSharedState *antlr_batch_parse_cache_state = NULL;
static HTAB *antlr_batch_parse_cache_hash = NULL;

/*****************************************
 *    LOOKUP RESULT (local copies, safe after lock release)
 *****************************************/
typedef struct AntlrBatchParseCacheLookupResult
{
	char	   *parse_tree;
	int			parse_tree_len;
	char	   *parse_datums;	/* NULL if none */
	int			parse_datums_len;
} AntlrBatchParseCacheLookupResult;

/*****************************************
 *    PER-BATCH CONTEXT
 *****************************************/
typedef struct AntlrBatchParseCacheCtx
{
	const char *query_text;
	AntlrBatchParseCacheKey key;
	uint64		param_sig;
	int			pre_cache_nDatums;	/* datums created before ANTLR */
} AntlrBatchParseCacheCtx;


/* ----------------------------------------------------------------
 * Shared Memory Startup
 *
 * Attach to the state and hash created by babelfishpg_tds. Idempotent.
 * ----------------------------------------------------------------
 */
void
antlr_batch_parse_cache_shmem_startup(void)
{
	bool		found_state;
	HASHCTL		info;
	AntlrBatchParseCacheSharedState *state;

	if (antlr_batch_parse_cache_hash != NULL)
		return;					/* Already attached */

	/*
	 * The shared memory exists only if babelfishpg_tds created it at startup.
	 * Do not call ShmemInitStruct() otherwise: in a backend it would allocate
	 * a new, uninitialized struct that later backends would attach to.
	 */
	{
		const char *enabled = GetConfigOption(ANTLR_BATCH_PARSE_CACHE_ENABLE_GUC, true, false);

		if (enabled == NULL || strcmp(enabled, "on") != 0)
			return;
	}

	LWLockAcquire(AddinShmemInitLock, LW_EXCLUSIVE);

	state = ShmemInitStruct(ANTLR_BATCH_PARSE_CACHE_SHMEM_STATE_NAME,
							sizeof(AntlrBatchParseCacheSharedState),
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
	info.keysize = sizeof(AntlrBatchParseCacheKey);
	info.entrysize = sizeof(AntlrBatchParseCacheEntry);
	antlr_batch_parse_cache_hash = ShmemInitHash(ANTLR_BATCH_PARSE_CACHE_SHMEM_HASH_NAME,
												 ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES,
												 ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES,
												 &info,
												 HASH_ELEM | HASH_BLOBS);
	antlr_batch_parse_cache_state = state;

	LWLockRelease(AddinShmemInitLock);
}

/* 64-bit hash of a NUL-terminated string */
static uint64
antlr_batch_parse_cache_hash_cstring(const char *str)
{
	return DatumGetUInt64(hash_any_extended((const unsigned char *) str,
											strlen(str), 0));
}

/* ----------------------------------------------------------------
 * Parameter Signature
 *
 * Parameter count, names, types, and modes change the ANTLR output (dno
 * layout, assignment casts). Types are hashed by schema-qualified name,
 * not OID. Typmod is excluded: parameters are built with typmod -1, so it
 * never reaches ANTLR.
 * ----------------------------------------------------------------
 */
static uint64
compute_antlr_batch_parse_cache_param_sig(int numargs, const Oid *argtypes,
										  const char *argmodes,
										  char **argnames)
{
	uint64		sig = (uint64) numargs;
	int			i;

	for (i = 0; i < numargs; i++)
	{
		Oid			typoid = argtypes ? argtypes[i] : InvalidOid;

		if (OidIsValid(typoid))
		{
			char	   *typname = format_type_extended(typoid, -1,
													   FORMAT_TYPE_FORCE_QUALIFY |
													   FORMAT_TYPE_ALLOW_INVALID);

			sig = hash_combine64(sig, antlr_batch_parse_cache_hash_cstring(typname));
			pfree(typname);
		}
		else
			sig = hash_combine64(sig, 0);

		sig = hash_combine64(sig, (uint64) (unsigned char) (argmodes ? argmodes[i] : 'i'));

		if (argnames && argnames[i])
			sig = hash_combine64(sig, antlr_batch_parse_cache_hash_cstring(argnames[i]));
		else
			sig = hash_combine64(sig, 0);
	}

	return sig;
}

/* Cache key: hash of query text, db_id, and parameter signature */
static AntlrBatchParseCacheKey
compute_antlr_batch_parse_cache_key(const char *query_text, int16 db_id, uint64 param_sig)
{
	uint64		hash;

	hash = DatumGetUInt64(hash_any_extended((const unsigned char *) query_text,
											strlen(query_text),
											0));
	hash = hash_combine64(hash, (uint64) db_id);
	hash = hash_combine64(hash, param_sig);
	return (AntlrBatchParseCacheKey) hash;
}


/* ================================================================
 * Layer 1: Shared memory hash table management
 *
 * Callers hold antlr_batch_parse_cache_state->lock (shared for find and touch,
 * exclusive for enter, remove, evict, and fill). None of these raise
 * an ERROR.
 * ================================================================
 */

/* True once attached to the shared memory created by babelfishpg_tds */
static inline bool
antlr_batch_parse_cache_attached(void)
{
	return antlr_batch_parse_cache_hash != NULL && antlr_batch_parse_cache_state != NULL;
}

/* Get: the entry for a key, or NULL */
static AntlrBatchParseCacheEntry *
antlr_batch_parse_cache_hash_find(AntlrBatchParseCacheKey key)
{
	return (AntlrBatchParseCacheEntry *) hash_search(antlr_batch_parse_cache_hash, &key,
													 HASH_FIND, NULL);
}

/* Insert: a new or existing entry for a key; NULL if the table is full */
static AntlrBatchParseCacheEntry *
antlr_batch_parse_cache_hash_enter(AntlrBatchParseCacheKey key, bool *found)
{
	/* HASH_ENTER_NULL: returns NULL instead of raising ERROR */
	return (AntlrBatchParseCacheEntry *) hash_search(antlr_batch_parse_cache_hash, &key,
													 HASH_ENTER_NULL, found);
}

/* Delete: one entry */
static void
antlr_batch_parse_cache_hash_remove(AntlrBatchParseCacheKey key)
{
	hash_search(antlr_batch_parse_cache_hash, &key, HASH_REMOVE, NULL);
}

/* Delete: every entry; returns the number removed */
static int64
antlr_batch_parse_cache_hash_remove_all(void)
{
	HASH_SEQ_STATUS scan;
	AntlrBatchParseCacheEntry *entry;
	int64		removed = 0;

	hash_seq_init(&scan, antlr_batch_parse_cache_hash);
	while ((entry = (AntlrBatchParseCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		antlr_batch_parse_cache_hash_remove(entry->key);
		removed++;
	}
	return removed;
}

/* Eviction order: oldest last_used_at first */
static int
antlr_batch_parse_cache_entry_cmp(const void *a, const void *b)
{
	TimestampTz ts_a = (*(AntlrBatchParseCacheEntry **) a)->last_used_at;
	TimestampTz ts_b = (*(AntlrBatchParseCacheEntry **) b)->last_used_at;

	if (ts_a < ts_b)
		return -1;
	if (ts_a > ts_b)
		return 1;
	return 0;
}

/*
 * Delete: the least recently used 10% (min 5). entries_arr must hold
 * ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES pointers; it is allocated by the caller
 * before taking the lock.
 */
static void
antlr_batch_parse_cache_hash_evict_lru(AntlrBatchParseCacheEntry **entries_arr)
{
	HASH_SEQ_STATUS scan;
	AntlrBatchParseCacheEntry *scan_entry;
	long		num_entries = 0;
	long		num_to_drop;
	long		i;

	hash_seq_init(&scan, antlr_batch_parse_cache_hash);
	while ((scan_entry = (AntlrBatchParseCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		if (num_entries < ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES)
			entries_arr[num_entries++] = scan_entry;
	}

	qsort(entries_arr, num_entries, sizeof(AntlrBatchParseCacheEntry *),
		  antlr_batch_parse_cache_entry_cmp);

	num_to_drop = Max(ANTLR_BATCH_PARSE_CACHE_MIN_VICTIMS, num_entries * ANTLR_BATCH_PARSE_CACHE_DEALLOC_PERCENT / 100);
	num_to_drop = Min(num_to_drop, num_entries);

	for (i = 0; i < num_to_drop; i++)
	{
		antlr_batch_parse_cache_hash_remove(entries_arr[i]->key);
		pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_evictions, 1);
	}
}

/* True if the entry holds this query text and parameter signature */
static bool
antlr_batch_parse_cache_entry_matches(AntlrBatchParseCacheEntry *entry, const char *query_text,
									  int query_len, uint64 param_sig)
{
	return entry->query_text_len == query_len &&
		strncmp(entry->query_text, query_text, query_len) == 0 &&
		entry->param_sig == param_sig;
}

/* Update: mark the entry as just used. Safe under a shared lock. */
static void
antlr_batch_parse_cache_entry_touch(AntlrBatchParseCacheEntry *entry, TimestampTz now)
{
	SpinLockAcquire(&entry->mutex);
	entry->last_used_at = now;
	SpinLockRelease(&entry->mutex);
}

/* Update: copy the data into the entry. Needs the exclusive lock. */
static void
antlr_batch_parse_cache_entry_fill(AntlrBatchParseCacheEntry *entry, bool found,
								   const char *query_text, int query_len,
								   const char *tree_str, int tree_len,
								   const char *datums_str, int datums_len,
								   uint64 param_sig, int pre_cache_nDatums)
{
	memcpy(entry->query_text, query_text, query_len);
	entry->query_text[query_len] = '\0';
	entry->query_text_len = query_len;

	memcpy(entry->parse_tree, tree_str, tree_len);
	entry->parse_tree[tree_len] = '\0';
	entry->parse_tree_len = tree_len;

	if (datums_len > 0)
		memcpy(entry->parse_datums, datums_str, datums_len);
	entry->parse_datums[datums_len] = '\0';
	entry->parse_datums_len = datums_len;

	strlcpy(entry->bbf_version, BABELFISH_VERSION_STR, sizeof(entry->bbf_version));
	entry->param_sig = param_sig;
	entry->pre_cache_nDatums = pre_cache_nDatums;
	entry->last_used_at = GetCurrentTimestamp();

	if (!found)
	{
		entry->created_at = entry->last_used_at;
		SpinLockInit(&entry->mutex);
	}
}

/* palloc'd copy of the entry's tree and datums */
static AntlrBatchParseCacheLookupResult *
antlr_batch_parse_cache_entry_copy(AntlrBatchParseCacheEntry *entry)
{
	AntlrBatchParseCacheLookupResult *result;

	result = (AntlrBatchParseCacheLookupResult *) palloc(sizeof(AntlrBatchParseCacheLookupResult));

	result->parse_tree_len = entry->parse_tree_len;
	result->parse_tree = palloc(entry->parse_tree_len + 1);
	memcpy(result->parse_tree, entry->parse_tree, entry->parse_tree_len);
	result->parse_tree[entry->parse_tree_len] = '\0';

	result->parse_datums_len = entry->parse_datums_len;
	result->parse_datums = NULL;
	if (entry->parse_datums_len > 0)
	{
		result->parse_datums = palloc(entry->parse_datums_len + 1);
		memcpy(result->parse_datums, entry->parse_datums, entry->parse_datums_len);
		result->parse_datums[entry->parse_datums_len] = '\0';
	}

	return result;
}

static void
antlr_batch_parse_cache_free_result(AntlrBatchParseCacheLookupResult *result)
{
	if (result->parse_tree)
		pfree(result->parse_tree);
	if (result->parse_datums)
		pfree(result->parse_datums);
	pfree(result);
}

/* True if the serialized sizes fit the buffers and the min/max size GUCs */
static bool
antlr_batch_parse_cache_entry_size_ok(int query_len, int tree_len, int datums_len)
{
	int			total_data_len = query_len + tree_len + datums_len;
	int			min_bytes = pltsql_antlr_batch_parse_cache_min_entry_size * 1024;
	int			max_bytes = pltsql_antlr_batch_parse_cache_max_entry_size * 1024;

	if (query_len >= ANTLR_BATCH_PARSE_CACHE_MAX_QUERY_TEXT_LEN ||
		tree_len >= ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_TREE_LEN ||
		datums_len >= ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_DATUMS_LEN)
	{
		elog(DEBUG1, "antlr_batch_parse_cache: entry exceeds buffer limit (query=%d tree=%d datums=%d), skipping",
			 query_len, tree_len, datums_len);
		return false;
	}

	if (total_data_len < min_bytes)
	{
		elog(DEBUG1, "antlr_batch_parse_cache: entry too small (%d bytes, min %d bytes), skipping",
			 total_data_len, min_bytes);
		return false;
	}

	if (max_bytes > 0 && total_data_len > max_bytes)
	{
		elog(DEBUG1, "antlr_batch_parse_cache: entry too large (%d bytes, max %d bytes), skipping",
			 total_data_len, max_bytes);
		return false;
	}

	return true;
}


/* ================================================================
 * Layer 2: Cache get / put / flush
 * ================================================================
 */

/*
 * Get: palloc'd copies of the entry, made under the shared lock, or NULL
 * on miss. Any mismatch in text, parameter signature, datum count, or
 * version is a miss. Caller frees the result.
 */
static AntlrBatchParseCacheLookupResult *
antlr_batch_parse_cache_get(const AntlrBatchParseCacheCtx *ctx)
{
	AntlrBatchParseCacheEntry *entry;
	AntlrBatchParseCacheLookupResult *result;
	TimestampTz now;

	if (!antlr_batch_parse_cache_attached())
		return NULL;

	LWLockAcquire(antlr_batch_parse_cache_state->lock, LW_SHARED);

	entry = antlr_batch_parse_cache_hash_find(ctx->key);

	if (entry == NULL ||
		!antlr_batch_parse_cache_entry_matches(entry, ctx->query_text,
											   (int) strlen(ctx->query_text),
											   ctx->param_sig) ||
		entry->pre_cache_nDatums != ctx->pre_cache_nDatums ||
		strcmp(entry->bbf_version, BABELFISH_VERSION_STR) != 0 ||
		entry->parse_tree_len <= 0)
	{
		pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_misses, 1);
		LWLockRelease(antlr_batch_parse_cache_state->lock);
		return NULL;
	}

	/* Copy under the lock so a concurrent eviction cannot overwrite it */
	result = antlr_batch_parse_cache_entry_copy(entry);

	/* Read the clock outside the spinlock */
	now = GetCurrentTimestamp();
	antlr_batch_parse_cache_entry_touch(entry, now);

	pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_hits, 1);

	LWLockRelease(antlr_batch_parse_cache_state->lock);

	return result;
}

/*
 * Put: insert or update the entry, evicting first if the cache is full.
 * Returns false if the entry was skipped.
 */
static bool
antlr_batch_parse_cache_put(const AntlrBatchParseCacheCtx *ctx, const char *tree_str,
							const char *datums_str)
{
	AntlrBatchParseCacheEntry *entry;
	AntlrBatchParseCacheEntry **entries_arr;
	bool		found;
	int			query_len;
	int			tree_len;
	int			datums_len;

	if (!antlr_batch_parse_cache_attached())
		return false;

	query_len = strlen(ctx->query_text);
	tree_len = strlen(tree_str);
	datums_len = datums_str ? strlen(datums_str) : 0;

	if (!antlr_batch_parse_cache_entry_size_ok(query_len, tree_len, datums_len))
		return false;

	/*
	 * Allocate before locking: nothing may raise an ERROR under the lock,
	 * since the caller's FlushErrorState() does not release LWLocks.
	 */
	entries_arr = (AntlrBatchParseCacheEntry **)
		palloc(sizeof(AntlrBatchParseCacheEntry *) * ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES);

	LWLockAcquire(antlr_batch_parse_cache_state->lock, LW_EXCLUSIVE);

	entry = antlr_batch_parse_cache_hash_find(ctx->key);
	found = (entry != NULL);

	/* Key already used by different text or signature */
	if (found &&
		!antlr_batch_parse_cache_entry_matches(entry, ctx->query_text, query_len,
											   ctx->param_sig))
	{
		pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_errors, 1);
		LWLockRelease(antlr_batch_parse_cache_state->lock);
		pfree(entries_arr);
		ereport(LOG,
				(errmsg("Hash collision in batch query parse cache"),
				 errdetail("Cache Key: %lu",
						   (unsigned long) ctx->key)));
		return false;
	}

	if (!found)
	{
		if (hash_get_num_entries(antlr_batch_parse_cache_hash) >= (long) pltsql_antlr_batch_parse_cache_max_entries)
			antlr_batch_parse_cache_hash_evict_lru(entries_arr);

		entry = antlr_batch_parse_cache_hash_enter(ctx->key, &found);
		if (entry == NULL)
		{
			pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_errors, 1);
			LWLockRelease(antlr_batch_parse_cache_state->lock);
			pfree(entries_arr);
			return false;
		}
	}

	antlr_batch_parse_cache_entry_fill(entry, found,
									   ctx->query_text, query_len,
									   tree_str, tree_len,
									   datums_str, datums_len,
									   ctx->param_sig, ctx->pre_cache_nDatums);

	pg_atomic_add_fetch_u64(&antlr_batch_parse_cache_state->stat_writes, 1);

	LWLockRelease(antlr_batch_parse_cache_state->lock);
	pfree(entries_arr);
	return true;
}

/* Flush: remove every entry and reset the stats */
static int64
antlr_batch_parse_cache_flush(void)
{
	int64		flushed;

	if (!antlr_batch_parse_cache_attached())
		return 0;

	LWLockAcquire(antlr_batch_parse_cache_state->lock, LW_EXCLUSIVE);

	flushed = antlr_batch_parse_cache_hash_remove_all();

	pg_atomic_write_u64(&antlr_batch_parse_cache_state->stat_hits, 0);
	pg_atomic_write_u64(&antlr_batch_parse_cache_state->stat_misses, 0);
	pg_atomic_write_u64(&antlr_batch_parse_cache_state->stat_writes, 0);
	pg_atomic_write_u64(&antlr_batch_parse_cache_state->stat_evictions, 0);
	pg_atomic_write_u64(&antlr_batch_parse_cache_state->stat_errors, 0);

	LWLockRelease(antlr_batch_parse_cache_state->lock);

	return flushed;
}


/* ================================================================
 * Layer 3: Parse cache for pltsql_compile_inline()
 * ================================================================
 */

/*
 * antlr_batch_parse_cache_type_is_cacheable - true if the variable's type and collation
 * are built-in. A user-defined type or collation referenced by an unqualified
 * name could resolve to a different OID in another session, so a batch that
 * declares one must not be cached (the resolved OID is baked into the datum).
 */
static bool
antlr_batch_parse_cache_type_is_cacheable(PLtsql_type *dtype)
{
	HeapTuple	tp;
	Oid			nsp;

	if (dtype == NULL)
		return false;

	tp = SearchSysCache1(TYPEOID, ObjectIdGetDatum(dtype->typoid));
	if (!HeapTupleIsValid(tp))
		return false;
	nsp = ((Form_pg_type) GETSTRUCT(tp))->typnamespace;
	ReleaseSysCache(tp);
	if (!is_namespace_sys_or_pg_catalog(nsp))
		return false;

	/* InvalidOid collation = none/default, which is safe */
	if (OidIsValid(dtype->collation))
	{
		tp = SearchSysCache1(COLLOID, ObjectIdGetDatum(dtype->collation));
		if (!HeapTupleIsValid(tp))
			return false;
		nsp = ((Form_pg_collation) GETSTRUCT(tp))->collnamespace;
		ReleaseSysCache(tp);
		if (!is_namespace_sys_or_pg_catalog(nsp))
			return false;
	}

	return true;
}

/* True if a datum created by ANTLR can be shared with other sessions */
static bool
antlr_batch_parse_cache_datum_is_cacheable(PLtsql_datum *d)
{
	/* A NULL slot would shift dnos on restore */
	if (d == NULL)
		return false;

	switch (d->dtype)
	{
		case PLTSQL_DTYPE_VAR:
			return antlr_batch_parse_cache_type_is_cacheable(((PLtsql_var *) d)->datatype);

		case PLTSQL_DTYPE_ROW:

			/*
			 * A row (e.g. a SELECT-assignment target) carries no type OID of
			 * its own; it references its member datums by number, and those
			 * members are checked on their own.
			 */
			return true;

		default:

			/*
			 * Record or table variable may carry a user-defined composite or
			 * table-type OID; be conservative and do not cache.
			 */
			return false;
	}
}

/* Deserialize the cached tree; NULL on failure */
static PLtsql_stmt_block *
antlr_batch_parse_cache_restore_tree(const char *tree_str)
{
	PLtsql_stmt_block *tree = NULL;

	PG_TRY();
	{
		tree = (PLtsql_stmt_block *) pltsql_stringToNode(tree_str);
	}
	PG_CATCH();
	{
		FlushErrorState();
		tree = NULL;
		elog(DEBUG1, "pltsql_antlr_batch_parse_cache: deserialization failed, falling through to ANTLR");
	}
	PG_END_TRY();

	return tree;
}

/*
 * Deserialize the cached datums and add them. The tree refers to datums by
 * dno, so every dno is checked before any is added. Returns false (and adds
 * nothing) on failure.
 */
static bool
antlr_batch_parse_cache_restore_datums(const char *datums_str)
{
	List	   *datum_list = NIL;
	ListCell   *lc;
	int			expected_dno = pltsql_nDatums;

	PG_TRY();
	{
		datum_list = (List *) pltsql_stringToNode(datums_str);
	}
	PG_CATCH();
	{
		FlushErrorState();
		datum_list = NIL;
	}
	PG_END_TRY();

	if (datum_list == NIL)
	{
		elog(DEBUG1, "pltsql_antlr_batch_parse_cache: datum deserialization failed, falling through to ANTLR");
		return false;
	}

	foreach(lc, datum_list)
	{
		PLtsql_datum *d = (PLtsql_datum *) lfirst(lc);

		if (d == NULL || d->dno != expected_dno++)
		{
			list_free(datum_list);
			elog(DEBUG1, "pltsql_antlr_batch_parse_cache: cached datum numbering mismatch, falling through to ANTLR");
			return false;
		}
	}

	foreach(lc, datum_list)
		pltsql_adddatum((PLtsql_datum *) lfirst(lc));

	list_free(datum_list);
	return true;
}

/*
 * Validation mode (debug): re-parse and compare trees and datums. Rewind
 * the datum count so the fresh parse numbers datums the same way, then
 * restore the cached state.
 */
static void
antlr_batch_parse_cache_validate_hit(const AntlrBatchParseCacheCtx *ctx, const char *proc_source,
									 PLtsql_stmt_block *cached_tree)
{
	int			pre = ctx->pre_cache_nDatums;
	int			n_cached = pltsql_nDatums - pre;
	PLtsql_datum **saved = NULL;
	int			si;

	if (n_cached > 0)
	{
		saved = (PLtsql_datum **) palloc(sizeof(PLtsql_datum *) * n_cached);
		memcpy(saved, &pltsql_Datums[pre], sizeof(PLtsql_datum *) * n_cached);
	}
	pltsql_nDatums = pre;

	PG_TRY();
	{
		ANTLR_result fresh_result = antlr_parser_cpp(proc_source);

		if (fresh_result.success)
		{
			char	   *cached_str = pltsql_nodeToString(cached_tree);
			char	   *fresh_str = pltsql_nodeToString(pltsql_parse_result);
			bool		match = (strcmp(cached_str, fresh_str) == 0) &&
				(pltsql_nDatums - pre == n_cached);

			for (si = 0; match && si < n_cached; si++)
			{
				char	   *c = pltsql_nodeToString(saved[si]);
				char	   *f = pltsql_nodeToString(pltsql_Datums[pre + si]);

				match = (strcmp(c, f) == 0);
				pfree(c);
				pfree(f);
			}

			if (match)
				elog(LOG, "antlr_batch_parse_cache[VALIDATE]: PASS key=%lu",
					 (unsigned long) ctx->key);
			else
				elog(WARNING, "antlr_batch_parse_cache[VALIDATE]: FAIL key=%lu - cached tree differs from fresh ANTLR parse",
					 (unsigned long) ctx->key);

			pfree(cached_str);
			pfree(fresh_str);
		}
		else
			elog(WARNING, "antlr_batch_parse_cache[VALIDATE]: fresh ANTLR parse failed, cannot validate");
	}
	PG_CATCH();
	{
		FlushErrorState();
		elog(WARNING, "antlr_batch_parse_cache[VALIDATE]: error during validation, continuing with cached tree");
	}
	PG_END_TRY();

	/* Put the cached tree and datums back */
	pltsql_parse_result = cached_tree;
	pltsql_nDatums = pre;
	for (si = 0; si < n_cached; si++)
		pltsql_adddatum(saved[si]);
	if (saved)
		pfree(saved);
}

/*
 * Cache read: on a hit, install the cached tree and datums and return true.
 * On a miss or any restore failure, return false with no state changed.
 */
static bool
antlr_batch_parse_cache_read(const AntlrBatchParseCacheCtx *ctx, const char *proc_source)
{
	AntlrBatchParseCacheLookupResult *cached;
	PLtsql_stmt_block *tree;
	instr_time	deser_start,
				deser_end;

	cached = antlr_batch_parse_cache_get(ctx);
	if (cached == NULL)
		return false;

	INSTR_TIME_SET_CURRENT(deser_start);

	tree = antlr_batch_parse_cache_restore_tree(cached->parse_tree);

	if (tree != NULL && cached->parse_datums != NULL &&
		!antlr_batch_parse_cache_restore_datums(cached->parse_datums))
		tree = NULL;

	antlr_batch_parse_cache_free_result(cached);

	if (tree == NULL)
		return false;

	pltsql_parse_result = tree;

	/* Record deserialization time for EXPLAIN reporting */
	INSTR_TIME_SET_CURRENT(deser_end);
	INSTR_TIME_SUBTRACT(deser_end, deser_start);
	antlr_parse_time = deser_end;

	elog(DEBUG1, "antlr_batch_parse_cache[HIT]: key=%lu (deser_time=%.3f ms)",
		 (unsigned long) ctx->key,
		 1000.0 * INSTR_TIME_GET_DOUBLE(deser_end));

	if (pltsql_validate_antlr_batch_parse_cache)
		antlr_batch_parse_cache_validate_hit(ctx, proc_source, tree);

	return true;
}

/*
 * Serialize the datums ANTLR created (dno >= pre_cache_nDatums). Sets
 * *cacheable to false if any of them must not be shared. Returns NULL if
 * there are none.
 */
static char *
antlr_batch_parse_cache_serialize_datums(int pre_cache_nDatums, bool *cacheable)
{
	List	   *datum_list = NIL;
	char	   *datums_str = NULL;
	int			di;

	*cacheable = true;

	for (di = pre_cache_nDatums; di < pltsql_nDatums; di++)
	{
		PLtsql_datum *d = pltsql_Datums[di];

		if (!antlr_batch_parse_cache_datum_is_cacheable(d))
		{
			*cacheable = false;
			break;
		}
		datum_list = lappend(datum_list, d);
	}

	if (*cacheable && datum_list != NIL)
		datums_str = pltsql_nodeToString(datum_list);
	list_free(datum_list);

	return datums_str;
}

/* Cache write: store the result of a successful fresh ANTLR parse */
static void
antlr_batch_parse_cache_write(const AntlrBatchParseCacheCtx *ctx)
{
	PG_TRY();
	{
		char	   *tree_str = NULL;
		char	   *datums_str;
		bool		cacheable;

		datums_str = antlr_batch_parse_cache_serialize_datums(ctx->pre_cache_nDatums,
															  &cacheable);
		if (cacheable)
		{
			tree_str = pltsql_nodeToString(pltsql_parse_result);
			antlr_batch_parse_cache_put(ctx, tree_str, datums_str);
			elog(DEBUG1, "antlr_batch_parse_cache[WRITE]: key=%lu",
				 (unsigned long) ctx->key);
		}

		if (tree_str)
			pfree(tree_str);
		if (datums_str)
			pfree(datums_str);
	}
	PG_CATCH();
	{
		FlushErrorState();
		elog(DEBUG1, "antlr_batch_parse_cache[FAIL]: write failed, continuing normally");
	}
	PG_END_TRY();
}

/* Normal ANTLR parse; returns 0 on success, 1 on invalid input */
static int
antlr_batch_parse_cache_antlr_parse(const char *proc_source)
{
	ANTLR_result result = antlr_parser_cpp(proc_source);

	if (result.success)
		return 0;

	report_antlr_error(result);
	return 1;					/* invalid input */
}

/*
 * antlr_batch_parse_cache_enabled - true if this inline batch should go through the
 * cache: feature on, TDS connection, not dump/restore, and an sp_prepexec
 * batch (CACHE_PLAN).
 */
bool
antlr_batch_parse_cache_enabled(InlineCodeBlockArgs *args)
{
	return antlr_batch_parse_cache_attached() &&
		IS_TDS_CONN() &&
		!babelfish_dump_restore &&
		args != NULL &&
		OPTION_ENABLED(args, CACHE_PLAN);
}

/*
 * antlr_batch_parse_cache_get_or_parse - parse proc_source using the cache.
 *
 * On a hit, pltsql_parse_result and the datums come from the cache. On a
 * miss, run ANTLR and store the result. Returns the parse return code
 * (0 on success). Call only when antlr_batch_parse_cache_enabled(args) is true.
 */
int
antlr_batch_parse_cache_get_or_parse(const char *proc_source, InlineCodeBlockArgs *args)
{
	AntlrBatchParseCacheCtx ctx;
	int			parse_rc;

	ctx.query_text = proc_source;
	ctx.pre_cache_nDatums = pltsql_nDatums;
	/* Parameter count, type names, modes and names */
	ctx.param_sig = compute_antlr_batch_parse_cache_param_sig(args->numargs,
															  args->argtypes,
															  args->argmodes,
															  args->argnames);
	ctx.key = compute_antlr_batch_parse_cache_key(proc_source, get_cur_db_id(),
												  ctx.param_sig);

	if (antlr_batch_parse_cache_read(&ctx, proc_source))
		return 0;

	parse_rc = antlr_batch_parse_cache_antlr_parse(proc_source);
	if (parse_rc == 0)
		antlr_batch_parse_cache_write(&ctx);

	return parse_rc;
}


/* ----------------------------------------------------------------
 * SQL-callable Functions
 * ----------------------------------------------------------------
 */

Datum
antlr_batch_parse_cache_stats(PG_FUNCTION_ARGS)
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

	if (antlr_batch_parse_cache_attached())
	{
		values[0] = Int64GetDatum((int64) pg_atomic_read_u64(&antlr_batch_parse_cache_state->stat_hits));
		values[1] = Int64GetDatum((int64) pg_atomic_read_u64(&antlr_batch_parse_cache_state->stat_misses));
		values[2] = Int64GetDatum((int64) pg_atomic_read_u64(&antlr_batch_parse_cache_state->stat_writes));
		values[3] = Int64GetDatum((int64) pg_atomic_read_u64(&antlr_batch_parse_cache_state->stat_evictions));
		values[4] = Int64GetDatum((int64) pg_atomic_read_u64(&antlr_batch_parse_cache_state->stat_errors));
		values[5] = Int64GetDatum(hash_get_num_entries(antlr_batch_parse_cache_hash));
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
flush_antlr_batch_parse_cache(PG_FUNCTION_ARGS)
{
	int64		flushed;

	/* Only sysadmin can access cache functions */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Only sysadmin can access batch query parse cache functions.")));

	flushed = antlr_batch_parse_cache_flush();
	PG_RETURN_BOOL(flushed > 0);
}

/* Return one row per cache entry */
Datum
antlr_batch_parse_cache_entries(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	HASH_SEQ_STATUS scan;
	AntlrBatchParseCacheEntry *entry;

	/* Only sysadmin can access cache functions */
	if (!has_privs_of_role(GetSessionUserId(), get_sysadmin_oid()))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("Only sysadmin can access batch query parse cache functions.")));

#define ANTLR_BATCH_PARSE_CACHE_ENTRIES_COLS 7

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
	if (!antlr_batch_parse_cache_attached())
		return (Datum) 0;

	LWLockAcquire(antlr_batch_parse_cache_state->lock, LW_SHARED);

	hash_seq_init(&scan, antlr_batch_parse_cache_hash);
	while ((entry = (AntlrBatchParseCacheEntry *) hash_seq_search(&scan)) != NULL)
	{
		Datum		values[ANTLR_BATCH_PARSE_CACHE_ENTRIES_COLS];
		bool		nulls[ANTLR_BATCH_PARSE_CACHE_ENTRIES_COLS];

		memset(nulls, 0, sizeof(nulls));

		values[0] = UInt64GetDatum(entry->key);
		values[1] = TimestampTzGetDatum(entry->created_at);
		values[2] = TimestampTzGetDatum(entry->last_used_at);
		values[3] = Int32GetDatum(entry->query_text_len);
		values[4] = Int32GetDatum(entry->parse_tree_len);
		values[5] = Int32GetDatum(entry->parse_datums_len);
		values[6] = CStringGetTextDatum(entry->bbf_version);

		tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	LWLockRelease(antlr_batch_parse_cache_state->lock);

	return (Datum) 0;
}
