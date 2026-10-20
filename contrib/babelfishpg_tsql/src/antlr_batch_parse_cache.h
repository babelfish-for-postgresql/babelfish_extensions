/*-------------------------------------------------------------------------
 *
 * antlr_batch_parse_cache.h
 *    Shared memory ANTLR parse tree cache for batch T-SQL queries.
 *
 * Key: query text + database id + parameter signature (parameter
 * count, type names, modes and names). Query text is kept only for
 * collision checks; sys.antlr_batch_parse_cache_entries() exposes metadata
 * (sizes, timestamps, version), not the query text or parse tree.
 *
 *-------------------------------------------------------------------------
 */
#ifndef ANTLR_BATCH_PARSE_CACHE_H
#define ANTLR_BATCH_PARSE_CACHE_H

#include "postgres.h"
#include "port/atomics.h"
#include "storage/lwlock.h"
#include "storage/s_lock.h"

/*****************************************
 *    BUFFER SIZE LIMITS
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_MAX_QUERY_TEXT_LEN	(64 * 1024) /* 64 KB */
#define ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_TREE_LEN	(160 * 1024)	/* 160 KB */
#define ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_DATUMS_LEN (32 * 1024)	/* 32 KB */

/*****************************************
 *    HASH TABLE CAPACITY
 *
 *    Fixed: shared memory hash tables cannot grow. Upper bound of
 *    antlr_batch_parse_cache_max_entries.
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_DEFAULT_MAX_ENTRIES	1000

/*****************************************
 *    ENABLE GUC
 *
 *    Defined by babelfishpg_tds (PGC_POSTMASTER, so it must come from a
 *    preloaded library). When off, the shared memory is not created and the
 *    cache stays disabled. babelfishpg_tsql reads it by name.
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_ENABLE_GUC	"babelfishpg_tds.enable_antlr_batch_parse_cache"

/*****************************************
 *    SHARED MEMORY NAMES
 *
 *    Created by babelfishpg_tds, attached by babelfishpg_tsql; both must
 *    use the same names.
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_SHMEM_STATE_NAME	"antlr_batch_parse_cache_state"
#define ANTLR_BATCH_PARSE_CACHE_SHMEM_HASH_NAME		"antlr_batch_parse_cache_hash"
#define ANTLR_BATCH_PARSE_CACHE_LWLOCK_TRANCHE		"antlr_batch_parse_cache"

/*****************************************
 *    HASH KEY
 *****************************************/
typedef uint64 AntlrBatchParseCacheKey; /* hash of query text, db_id,
										 * param_sig */

/*****************************************
 *    HASH ENTRY
 *****************************************/
typedef struct AntlrBatchParseCacheEntry
{
	AntlrBatchParseCacheKey key;	/* hash lookup key — must be first */

	char		query_text[ANTLR_BATCH_PARSE_CACHE_MAX_QUERY_TEXT_LEN]; /* for collision checks */
	int			query_text_len;

	char		parse_tree[ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_TREE_LEN]; /* serialized tree */
	int			parse_tree_len;

	char		parse_datums[ANTLR_BATCH_PARSE_CACHE_MAX_PARSE_DATUMS_LEN]; /* serialized datums */
	int			parse_datums_len;

	char		bbf_version[32];
	uint64		param_sig;		/* parameter signature */
	int			pre_cache_nDatums;	/* datums before ANTLR; must match on hit */
	TimestampTz created_at;
	TimestampTz last_used_at;	/* LRU key */
	slock_t		mutex;			/* protects last_used_at */
} AntlrBatchParseCacheEntry;

/*****************************************
 *    SHARED STATE
 *****************************************/
typedef struct AntlrBatchParseCacheSharedState
{
	LWLock	   *lock;			/* protects the hash table */
	pg_atomic_uint64 stat_hits;
	pg_atomic_uint64 stat_misses;
	pg_atomic_uint64 stat_writes;
	pg_atomic_uint64 stat_evictions;
	pg_atomic_uint64 stat_errors;
} AntlrBatchParseCacheSharedState;

/*****************************************
 *    PUBLIC FUNCTIONS
 *****************************************/

/* Attach to the shared memory created by babelfishpg_tds; idempotent */
extern void antlr_batch_parse_cache_shmem_startup(void);

/*
 * Parse an inline batch through the cache. Used by pltsql_compile_inline():
 *
 *     if (antlr_batch_parse_cache_enabled(args))
 *         parse_rc = antlr_batch_parse_cache_get_or_parse(proc_source, args);
 *     else
 *         ... normal ANTLR parse ...
 *
 * Forward-declared so babelfishpg_tds can include this header for the
 * shared memory layout without pltsql.h.
 */
struct InlineCodeBlockArgs;
extern bool antlr_batch_parse_cache_enabled(struct InlineCodeBlockArgs *args);
extern int	antlr_batch_parse_cache_get_or_parse(const char *proc_source,
												 struct InlineCodeBlockArgs *args);

/* SQL-callable functions */
extern Datum antlr_batch_parse_cache_stats(PG_FUNCTION_ARGS);
extern Datum flush_antlr_batch_parse_cache(PG_FUNCTION_ARGS);
extern Datum antlr_batch_parse_cache_entries(PG_FUNCTION_ARGS);

#endif							/* ANTLR_BATCH_PARSE_CACHE_H */
