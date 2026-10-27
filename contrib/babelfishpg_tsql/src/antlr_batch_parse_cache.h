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
 *    CACHE AND SLOT SIZE
 *
 *    Both are fixed at server start (shared memory hash tables cannot grow):
 *    babelfishpg_tds.antlr_batch_parse_cache_size (MB) is the total and
 *    babelfishpg_tds.antlr_batch_parse_cache_slot_size (KB) is one whole
 *    entry, header included. Number of entries = total / slot size.
 *****************************************/
#define ANTLR_BATCH_PARSE_CACHE_DEFAULT_SIZE_MB		250
#define ANTLR_BATCH_PARSE_CACHE_MIN_SIZE_MB			100
#define ANTLR_BATCH_PARSE_CACHE_MAX_SIZE_MB			10000
#define ANTLR_BATCH_PARSE_CACHE_DEFAULT_SLOT_SIZE_KB	256
#define ANTLR_BATCH_PARSE_CACHE_MIN_SLOT_SIZE_KB		10
#define ANTLR_BATCH_PARSE_CACHE_MAX_SLOT_SIZE_KB		10000

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

	int			query_text_len;
	int			parse_tree_len;
	int			parse_datums_len;

	char		bbf_version[32];
	uint64		param_sig;		/* parameter signature */
	int			pre_cache_nDatums;	/* datums before ANTLR; must match on hit */
	TimestampTz created_at;
	TimestampTz last_used_at;	/* LRU key */
	slock_t		mutex;			/* protects last_used_at */

	/*
	 * Query text, serialized tree and serialized datums, each NUL-terminated,
	 * stored back to back. Fills the rest of the slot.
	 */
	char		data[FLEXIBLE_ARRAY_MEMBER];
} AntlrBatchParseCacheEntry;

/* Bytes reserved per slot: the whole entry, header included */
static inline Size
antlr_batch_parse_cache_entry_size(int slot_size_kb)
{
	return MAXALIGN((Size) slot_size_kb * 1024);
}

/* Number of slots that fit in size_mb megabytes */
static inline long
antlr_batch_parse_cache_num_slots(int size_mb, int slot_size_kb)
{
	return (long) (((Size) size_mb * 1024 * 1024) /
				   antlr_batch_parse_cache_entry_size(slot_size_kb));
}

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
	/* Set by babelfishpg_tds when the hash is created */
	long		num_slots;		/* hash capacity */
	Size		entry_size;		/* bytes per slot, header included */
	int			data_capacity;	/* bytes per slot for text, tree and datums */
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
