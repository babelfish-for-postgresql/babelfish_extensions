-- Ad-hoc ANTLR parse tree cache
-- POC table creation and function definitions
-- Run this script after extension installation to enable the POC

-- Create the catalog table for ad-hoc parse tree caching
CREATE TABLE IF NOT EXISTS sys.babelfish_adhoc_parse_cache (
    query_hash_id   BIGINT NOT NULL,            -- hash of normalized query text
    db_id           SMALLINT NOT NULL,           -- logical database context
    normalized_query TEXT NOT NULL COLLATE "C",  -- normalized query (for collision detection)
    parse_tree      TEXT DEFAULT NULL,           -- serialized PLtsql_stmt_block
    parse_datums    TEXT DEFAULT NULL,           -- serialized PLtsql_datum array
    bbf_version     TEXT NOT NULL COLLATE "C",   -- Babelfish version at cache time
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    use_count       BIGINT NOT NULL DEFAULT 1,
    PRIMARY KEY (query_hash_id, db_id)
);

-- Index for LRU eviction (find oldest entries)
CREATE INDEX IF NOT EXISTS babelfish_adhoc_parse_cache_lru_idx
    ON sys.babelfish_adhoc_parse_cache (last_used_at ASC);

-- Grant read access to public (writes happen from backend C code)
GRANT SELECT ON sys.babelfish_adhoc_parse_cache TO PUBLIC;

-- Include in pg_dump
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_adhoc_parse_cache', '');

-- Session-level ad-hoc cache statistics function
CREATE OR REPLACE FUNCTION sys.adhoc_antlr_parse_cache_stats(
    OUT cache_hits INT,
    OUT cache_misses INT,
    OUT cache_writes INT,
    OUT cache_evictions INT,
    OUT cache_errors INT,
    OUT cache_entries INT
) RETURNS RECORD
AS 'babelfishpg_tsql', 'adhoc_antlr_parse_cache_stats'
LANGUAGE C VOLATILE PARALLEL RESTRICTED;

-- Flush (truncate) all entries from the ad-hoc parse cache
CREATE OR REPLACE FUNCTION sys.flush_adhoc_antlr_parse_cache()
RETURNS VOID
AS 'babelfishpg_tsql', 'flush_adhoc_antlr_parse_cache'
LANGUAGE C VOLATILE PARALLEL UNSAFE;
