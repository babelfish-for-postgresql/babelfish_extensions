/*-------------------------------------------------------------------------
 *
 * adhoc_cache.h
 *    Shared memory based ANTLR parse tree cache for ad-hoc T-SQL queries.
 *
 * Uses a shared memory hash table (ShmemInitHash) with a contiguous
 * buffer for storing variable-length serialized parse trees. Entries
 * are shared across all backends and persist for the server lifetime.
 *
 *-------------------------------------------------------------------------
 */
#ifndef ADHOC_CACHE_H
#define ADHOC_CACHE_H

#include "postgres.h"
#include "storage/lwlock.h"

/*****************************************
 *    CONFIGURATION
 *****************************************/
#define ADHOC_CACHE_MAX_QUERY_LEN		8192	/* max raw query text to cache */
#define ADHOC_CACHE_MAX_TREE_LEN		65536	/* max serialized tree per entry (64KB) */
#define ADHOC_CACHE_MAX_DATUMS_LEN		8192	/* max serialized datums per entry */

/*****************************************
 *    HASH KEY
 *****************************************/
typedef struct AdhocCacheKey
{
	int64		query_hash_id;		/* 64-bit hash of raw query text */
	int16		db_id;				/* logical database ID */
	int16		padding;			/* alignment padding */
} AdhocCacheKey;

/*****************************************
 *    HASH ENTRY (fixed size, stored in shmem)
 *****************************************/
typedef struct AdhocCacheEntry
{
	AdhocCacheKey key;				/* hash lookup key — must be first */

	/* Query text for collision detection */
	char		query_text[ADHOC_CACHE_MAX_QUERY_LEN];
	int			query_text_len;

	/* Serialized parse tree */
	char		parse_tree[ADHOC_CACHE_MAX_TREE_LEN];
	int			parse_tree_len;

	/* Serialized datums */
	char		parse_datums[ADHOC_CACHE_MAX_DATUMS_LEN];
	int			parse_datums_len;

	/* Metadata */
	char		bbf_version[32];
	int64		use_count;
	TimestampTz	created_at;
	TimestampTz	last_used_at;
} AdhocCacheEntry;

/*****************************************
 *    SHARED STATE
 *****************************************/
typedef struct AdhocCacheSharedState
{
	LWLock	   *lock;				/* protects hash table access */
	int64		total_entries;		/* current entry count */
	int64		stat_hits;			/* global hit counter */
	int64		stat_misses;		/* global miss counter */
	int64		stat_writes;		/* global write counter */
	int64		stat_evictions;		/* global eviction counter */
	int64		stat_errors;		/* global error counter */
} AdhocCacheSharedState;

/*****************************************
 *    GUC VARIABLES
 *****************************************/
extern bool pltsql_enable_adhoc_antlr_parse_cache;
extern int  pltsql_adhoc_parse_cache_max_entries;
extern bool pltsql_validate_adhoc_antlr_parse_cache;

/*****************************************
 *    PUBLIC FUNCTIONS
 *****************************************/

/* Shared memory initialization (called from hooks) */
extern void adhoc_cache_shmem_request(void);
extern void adhoc_cache_shmem_startup(void);

/* Hash computation */
extern int64 compute_adhoc_query_hash(const char *query_text);

/* Cache operations */
extern AdhocCacheEntry *adhoc_cache_lookup(int64 query_hash_id, int16 db_id,
										   const char *query_text);
extern bool adhoc_cache_insert(int64 query_hash_id, int16 db_id,
							   const char *query_text,
							   const char *parse_tree_str,
							   const char *parse_datums_str);
extern void adhoc_cache_flush(void);

/* SQL-callable functions */
extern Datum adhoc_antlr_parse_cache_stats(PG_FUNCTION_ARGS);
extern Datum flush_adhoc_antlr_parse_cache(PG_FUNCTION_ARGS);

#endif							/* ADHOC_CACHE_H */
