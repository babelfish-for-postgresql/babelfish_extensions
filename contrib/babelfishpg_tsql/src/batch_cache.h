/*-------------------------------------------------------------------------
 *
 * batch_cache.h
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * Each entry contains a single fixed-size data buffer that holds
 * query text, serialized parse tree, and datums concatenated together.
 * No external file or disk I/O is involved.
 *
 * Query text is stored for hash collision detection (strcmp on every
 * lookup) and is not exposed to customers via SQL functions.
 *
 * The cache works on Aurora read-only instances since all operations
 * are local shared memory (RAM).
 *
 *-------------------------------------------------------------------------
 */
#ifndef BATCH_CACHE_H
#define BATCH_CACHE_H

#include "postgres.h"
#include "storage/lwlock.h"
#include "storage/s_lock.h"

/*****************************************
 *    BUFFER SIZE LIMITS
 *****************************************/
#define BATCH_CACHE_MAX_QUERY_TEXT_LEN	(64 * 1024)		/* 64 KB */
#define BATCH_CACHE_MAX_PARSE_TREE_LEN	(160 * 1024)	/* 160 KB */
#define BATCH_CACHE_MAX_PARSE_DATUMS_LEN (32 * 1024)	/* 32 KB */

/*****************************************
 *    HASH KEY
 *****************************************/
typedef uint64 BatchCacheKey;	/* hash_combine64(query_text_hash, db_id) */

/*****************************************
 *    HASH ENTRY
 *
 *    Query text, parse tree, and datums are stored in separate
 *    fixed-size buffers within each entry.
 *****************************************/
typedef struct BatchCacheEntry
{
	BatchCacheKey key;				/* hash lookup key — must be first */

	/* Query text (for collision detection — not exposed to customers) */
	char		query_text[BATCH_CACHE_MAX_QUERY_TEXT_LEN];
	int			query_text_len;

	/* Serialized ANTLR parse tree */
	char		parse_tree[BATCH_CACHE_MAX_PARSE_TREE_LEN];
	int			parse_tree_len;

	/* Serialized datums */
	char		parse_datums[BATCH_CACHE_MAX_PARSE_DATUMS_LEN];
	int			parse_datums_len;

	/* Metadata */
	char		bbf_version[32];
	TimestampTz	created_at;
	TimestampTz	last_used_at;		/* LRU key — updated on every cache hit */
	slock_t		mutex;				/* per-entry spinlock for counter updates */
} BatchCacheEntry;

/*****************************************
 *    SHARED STATE
 *****************************************/
typedef struct BatchCacheSharedState
{
	LWLock	   *lock;				/* protects hash table structure (insert/remove/evict) */
	slock_t		mutex;				/* protects global stat counters */
	int64		stat_hits;			/* global hit counter */
	int64		stat_misses;		/* global miss counter */
	int64		stat_writes;		/* global write counter */
	int64		stat_evictions;		/* global eviction counter */
	int64		stat_errors;		/* global error counter */
} BatchCacheSharedState;

/*****************************************
 *    PUBLIC FUNCTIONS
 *****************************************/

/* Shared memory initialization (called from hooks) */
extern void batch_cache_shmem_request(void);
extern void batch_cache_shmem_startup(void);

/* Cache key computation */
extern BatchCacheKey compute_batch_cache_key(const char *query_text, int16 db_id);

/* Cache operations */
extern BatchCacheEntry *batch_cache_lookup(BatchCacheKey cache_key,
										   const char *query_text);
extern bool batch_cache_insert(BatchCacheKey cache_key,
							   const char *query_text,
							   const char *parse_tree_str,
							   const char *parse_datums_str);
extern int64 batch_cache_flush(void);

/* SQL-callable functions */
extern Datum batch_antlr_parse_cache_stats(PG_FUNCTION_ARGS);
extern Datum flush_batch_antlr_parse_cache(PG_FUNCTION_ARGS);
extern Datum batch_antlr_parse_cache_entries(PG_FUNCTION_ARGS);

#endif							/* BATCH_CACHE_H */
