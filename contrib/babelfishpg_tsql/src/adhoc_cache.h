/*-------------------------------------------------------------------------
 *
 * adhoc_cache.h
 *    Persistent ANTLR parse tree cache for ad-hoc T-SQL queries.
 *
 * This module provides caching of serialized ANTLR parse trees for ad-hoc
 * TDS batch queries in a dedicated catalog table. It allows repeated queries
 * with the same structure (differing only in literal values) to skip the
 * expensive ANTLR parsing step on subsequent executions.
 *
 *-------------------------------------------------------------------------
 */
#ifndef ADHOC_CACHE_H
#define ADHOC_CACHE_H

#include "postgres.h"
#include "pltsql.h"

/*****************************************
 *    ADHOC_PARSE_CACHE TABLE CONSTANTS
 *****************************************/
#define BBF_ADHOC_PARSE_CACHE_TABLE_NAME    "babelfish_adhoc_parse_cache"
#define BBF_ADHOC_PARSE_CACHE_IDX_NAME      "babelfish_adhoc_parse_cache_pkey"

/* Column numbers (1-based) */
#define Anum_adhoc_cache_query_hash_id      1
#define Anum_adhoc_cache_db_id              2
#define Anum_adhoc_cache_normalized_query   3
#define Anum_adhoc_cache_parse_tree         4
#define Anum_adhoc_cache_parse_datums       5
#define Anum_adhoc_cache_bbf_version        6
#define Anum_adhoc_cache_created_at         7
#define Anum_adhoc_cache_last_used_at       8
#define Anum_adhoc_cache_use_count          9
#define BBF_ADHOC_PARSE_CACHE_NUM_COLS      9

/*****************************************
 *    CACHE RESULT STRUCTURE
 *****************************************/
typedef struct AdhocCacheEntry
{
	int64		query_hash_id;
	int16		db_id;
	char	   *normalized_query;
	char	   *parse_tree;
	char	   *parse_datums;
	char	   *bbf_version;
} AdhocCacheEntry;

/*****************************************
 *    GUC VARIABLES (extern declarations)
 *****************************************/
extern bool pltsql_enable_adhoc_antlr_parse_cache;
extern int  pltsql_adhoc_parse_cache_max_entries;
extern bool pltsql_validate_adhoc_antlr_parse_cache;

/*****************************************
 *    STATISTICS COUNTERS
 *****************************************/
extern int pltsql_adhoc_cache_stat_hits;
extern int pltsql_adhoc_cache_stat_misses;
extern int pltsql_adhoc_cache_stat_writes;
extern int pltsql_adhoc_cache_stat_evictions;
extern int pltsql_adhoc_cache_stat_errors;

/*****************************************
 *    PUBLIC FUNCTION DECLARATIONS
 *****************************************/

/* Query normalization */
extern char *normalize_adhoc_query(const char *query_text);

/* Hash computation */
extern int64 compute_adhoc_query_hash(const char *normalized_text);

/* Cache table operations */
extern Oid  get_adhoc_parse_cache_oid(void);
extern Oid  get_adhoc_parse_cache_idx_oid(void);

/* Cache lookup: returns entry if found and valid, NULL otherwise */
extern AdhocCacheEntry *lookup_adhoc_parse_cache(int64 query_hash_id,
												 int16 db_id,
												 const char *normalized_query);

/* Cache write: insert or update entry */
extern void insert_adhoc_parse_cache(int64 query_hash_id,
									 int16 db_id,
									 const char *normalized_query,
									 const char *parse_tree_str,
									 const char *parse_datums_str);

/* Cache eviction: remove oldest entries when cache is full */
extern void evict_adhoc_parse_cache_if_needed(void);

/* Cache flush: remove all entries */
extern void flush_adhoc_parse_cache(void);

/* SQL-callable functions */
extern Datum adhoc_antlr_parse_cache_stats(PG_FUNCTION_ARGS);
extern Datum flush_adhoc_antlr_parse_cache(PG_FUNCTION_ARGS);

#endif							/* ADHOC_CACHE_H */
