/*-------------------------------------------------------------------------
 *
 * batch_cache.h
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * Key: query text + database id + compile signature (parameter declaration
 * and parse-affecting session settings). Query text is kept for collision
 * checks and is visible to sysadmin via sys.batch_antlr_parse_cache_entries().
 *
 *-------------------------------------------------------------------------
 */
#ifndef BATCH_CACHE_H
#define BATCH_CACHE_H

#include "postgres.h"
#include "port/atomics.h"
#include "storage/lwlock.h"
#include "storage/s_lock.h"

/*****************************************
 *    BUFFER SIZE LIMITS
 *****************************************/
#define BATCH_CACHE_MAX_QUERY_TEXT_LEN	(64 * 1024) /* 64 KB */
#define BATCH_CACHE_MAX_PARSE_TREE_LEN	(160 * 1024)	/* 160 KB */
#define BATCH_CACHE_MAX_PARSE_DATUMS_LEN (32 * 1024)	/* 32 KB */

/*****************************************
 *    HASH TABLE CAPACITY
 *
 *    Fixed: shared memory hash tables cannot grow. Upper bound of
 *    batch_query_cache_max_entries.
 *****************************************/
#define BATCH_CACHE_DEFAULT_MAX_ENTRIES	1000

/*****************************************
 *    HASH KEY
 *****************************************/
typedef uint64 BatchCacheKey;	/* hash of query text, db_id, compile_sig */

/*****************************************
 *    HASH ENTRY
 *****************************************/
typedef struct BatchCacheEntry
{
	BatchCacheKey key;			/* hash lookup key — must be first */

	char		query_text[BATCH_CACHE_MAX_QUERY_TEXT_LEN];	/* for collision checks */
	int			query_text_len;

	char		parse_tree[BATCH_CACHE_MAX_PARSE_TREE_LEN];	/* serialized tree */
	int			parse_tree_len;

	char		parse_datums[BATCH_CACHE_MAX_PARSE_DATUMS_LEN];	/* serialized datums */
	int			parse_datums_len;

	char		bbf_version[32];
	uint64		compile_sig;	/* parameter + parse-context signature */
	int			pre_cache_nDatums;	/* datums before ANTLR; must match on hit */
	TimestampTz created_at;
	TimestampTz last_used_at;	/* LRU key */
	slock_t		mutex;			/* protects last_used_at */
} BatchCacheEntry;

/*****************************************
 *    SHARED STATE
 *****************************************/
typedef struct BatchCacheSharedState
{
	LWLock	   *lock;			/* protects the hash table */
	pg_atomic_uint64 stat_hits;
	pg_atomic_uint64 stat_misses;
	pg_atomic_uint64 stat_writes;
	pg_atomic_uint64 stat_evictions;
	pg_atomic_uint64 stat_errors;
} BatchCacheSharedState;

/*****************************************
 *    LOOKUP RESULT (local copies, safe after lock release)
 *****************************************/
typedef struct BatchCacheLookupResult
{
	char	   *parse_tree;
	int			parse_tree_len;
	char	   *parse_datums;	/* NULL if none */
	int			parse_datums_len;
	int			pre_cache_nDatums;
} BatchCacheLookupResult;

/*****************************************
 *    PUBLIC FUNCTIONS
 *****************************************/

/* Attach to the shared memory created by babelfishpg_tds; idempotent */
extern void batch_cache_shmem_startup(void);

/* Cache key computation */
extern uint64 compute_batch_cache_param_sig(int numargs, const Oid *argtypes,
											const char *argmodes,
											char **argnames);
extern uint64 compute_batch_cache_parse_ctx_sig(void);
extern uint64 compute_batch_cache_compile_sig(int numargs, const Oid *argtypes,
											  const char *argmodes,
											  char **argnames);
extern BatchCacheKey compute_batch_cache_key(const char *query_text, int16 db_id,
											 uint64 compile_sig);

/* Lookup returns palloc'd copies, or NULL on miss */
extern BatchCacheLookupResult *batch_cache_lookup(BatchCacheKey cache_key,
												  const char *query_text,
												  uint64 compile_sig,
												  int pre_cache_nDatums);
extern bool batch_cache_insert(BatchCacheKey cache_key,
							   const char *query_text,
							   const char *parse_tree_str,
							   const char *parse_datums_str,
							   uint64 compile_sig,
							   int pre_cache_nDatums);
extern int64 batch_cache_flush(void);

/* SQL-callable functions */
extern Datum batch_antlr_parse_cache_stats(PG_FUNCTION_ARGS);
extern Datum flush_batch_antlr_parse_cache(PG_FUNCTION_ARGS);
extern Datum batch_antlr_parse_cache_entries(PG_FUNCTION_ARGS);

#endif							/* BATCH_CACHE_H */
