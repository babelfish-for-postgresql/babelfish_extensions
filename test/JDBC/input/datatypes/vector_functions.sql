select set_config('babelfishpg_tsql.explain_costs', 'off', false);
go
select set_config('babelfishpg_tsql.explain_timing', 'off', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'off', false);
go

-- functions
SELECT CAST('[1,2,3]' as vector) + '[4,5,6]';
go

SELECT CAST('[3e38]' as vector) + '[3e38]';
go

SELECT CAST('[1,2,3]' as vector) - '[4,5,6]';
go

SELECT CAST('[-3e38]' as vector) - '[3e38]';
go

SELECT CAST('[1,2,3]' as vector) * '[4,5,6]';
go

SELECT CAST('[1e37]' as vector) * '[1e37]';
go

SELECT CAST('[1e-37]' as vector) * '[1e-37]';
go

SELECT vector_dims('[1,2,3]');
go

SELECT round(cast(vector_norm('[1,1]') as numeric), 5);
go

SELECT vector_norm('[3,4]');
go

SELECT vector_norm('[0,1]');
go

SELECT vector_norm(Cast('[3e37,4e37]') as real);
go

SELECT l2_distance('[0,0]', '[3,4]');
go

SELECT l2_distance('[0,0]', '[0,1]');
go

SELECT l2_distance('[1,2]', '[3]');
go

SELECT l2_distance('[3e38]', '[-3e38]');
go

SELECT inner_product('[1,2]', '[3,4]');
go

SELECT inner_product('[1,2]', '[3]');
go

SELECT inner_product('[3e38]', '[3e38]');
go

SELECT cosine_distance('[1,2]', '[2,4]');
go

SELECT cosine_distance('[1,2]', '[0,0]');
go

SELECT cosine_distance('[1,1]', '[1,1]');
go

SELECT cosine_distance('[1,0]', '[0,2]');
go

SELECT cosine_distance('[1,1]', '[-1,-1]');
go

SELECT cosine_distance('[1,2]', '[3]');
go

SELECT cosine_distance('[1,1]', '[1.1,1.1]');
go

SELECT cosine_distance('[1,1]', '[-1.1,-1.1]');
go

SELECT cosine_distance('[3e38]', '[3e38]');
go

SELECT l1_distance('[0,0]', '[3,4]');
go

SELECT l1_distance('[0,0]', '[0,1]');
go

SELECT l1_distance('[1,2]', '[3]');
go

SELECT l1_distance('[3e38]', '[-3e38]');
go

SELECT vector_avg(array_agg(n)) FROM generate_series(1, 16002) n;
go

-- cast. has all arrays can prune maybe use array_to_vector

SELECT CAST(CAST('{NULL}' as real[]) as vector);
go

SELECT CAST(CAST('{NaN}' as real[]) as vector);
go

SELECT CAST(CAST('{Infinity}' as real[]) as vector);
go

-- SELECT '{-Infinity}'::real[]::vector;
-- go

-- SELECT '{}'::real[]::vector;
-- go

-- SELECT '{{1}}'::real[]::vector;
-- go

-- SELECT '[1,2,3]'::vector::real[];
-- go

SELECT CAST(array_agg(n) as vector) FROM generate_series(1, 16001) n;
go

SELECT array_to_vector(array_agg(n), 16001, false) FROM generate_series(1, 16001) n;
go

-- btree
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table (val);
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table WHERE val = '[1,2,3]';
go

SELECT TOP 1 * FROM vector_table ORDER BY val;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- hnsw_cosine
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table USING hnsw (val vector_cosine_ops);
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table ORDER BY val <=> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <=> '[0,0,0]') t2;
go
SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <=> (SELECT CAST(NULL as vector))) t2;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- hnsw_ip
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table USING hnsw (val vector_ip_ops);
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table ORDER BY val <#> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <#> '[0,0,0]') t2;
go
SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <#> (SELECT CAST(NULL as vector))) t2;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- hnsw_l2
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table USING hnsw (val vector_l2_ops);
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table ORDER BY val <-> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <-> '[0,0,0]') t2;
go
SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <-> (SELECT CAST(NULL as vector))) t2;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- hnsw options
CREATE TABLE vector_table (val vector(3));
go

CREATE INDEX idx1 ON vector_table USING hnsw (val vector_l2_ops) WITH (m = 1);
go

CREATE INDEX idx2 ON vector_table USING hnsw (val vector_l2_ops) WITH (m = 101);
go

CREATE INDEX idx3 ON vector_table USING hnsw (val vector_l2_ops) WITH (ef_construction = 3);
go

CREATE INDEX idx4 ON vector_table USING hnsw (val vector_l2_ops) WITH (ef_construction = 1001);
go

CREATE INDEX idx5 ON vector_table USING hnsw (val vector_l2_ops) WITH (m = 16, ef_construction = 31);
go

Select current_setting('hnsw.ef_search')
go

SELECT set_config('hnsw.ef_search', '0', false)
go

SELECT set_config('hnsw.ef_search', '1001', false)
go

DROP TABLE vector_table;
go

-- ivfflat cosine
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table USING ivfflat (val vector_cosine_ops) WITH (lists = 1);
go

INSERT INTO vector_table (val) VALUES ('[1,2,4]');
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table ORDER BY val <=> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <=> '[0,0,0]') t2;
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <=> (SELECT CAST(NULL as vector))) t2;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- ivfflat ip
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx2 ON vector_table USING ivfflat (val vector_ip_ops) WITH (lists = 1);
go

INSERT INTO vector_table (val) VALUES ('[1,2,4]');
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go

SELECT * FROM vector_table ORDER BY val <#> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <#> '[0,0,0]') t2;
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <#> (SELECT CAST(NULL as vector))) t2;
go


SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- ivfflat l2
CREATE TABLE vector_table (val vector(3));
go

INSERT INTO vector_table (val) VALUES ('[0,0,0]'), ('[1,2,3]'), ('[1,1,1]'), (NULL);
go

CREATE INDEX idx ON vector_table USING ivfflat (val vector_l2_ops) WITH (lists = 1);
go

INSERT INTO vector_table (val) VALUES ('[1,2,4]');
go

-- test explain output for index scan
SET BABELFISH_STATISTICS PROFILE ON; SELECT set_config('enable_seqscan', 'off', false);
go
SELECT * FROM vector_table ORDER BY val <-> '[3,3,3]';
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <-> '[0,0,0]') t2;
go

SELECT COUNT(*) FROM (SELECT * FROM vector_table ORDER BY val <-> (SELECT CAST(NULL as vector))) t2;
go

SET BABELFISH_STATISTICS PROFILE OFF; SELECT set_config('enable_seqscan', 'on', false);
DROP TABLE vector_table;
go

-- ivfflat options

CREATE TABLE vector_table (val vector(3));
go

CREATE INDEX idx1 ON vector_table USING ivfflat (val vector_l2_ops) WITH (lists = 0);
go

CREATE INDEX idx2 ON vector_table USING ivfflat (val vector_l2_ops) WITH (lists = 32769);
go

Select current_setting('ivfflat.probes')
go

DROP TABLE vector_table;
go

-- input
SELECT CAST('[1,2,3]' as vector);
go

SELECT CAST('[-1,-2,-3]' as vector);
go

SELECT CAST('[1.,2.,3.]' as vector);
go

SELECT CAST(' [ 1,  2 ,    3  ] ' as vector);
go

SELECT CAST('[1.23456]' as vector);
go

SELECT CAST('[hello,1]' as vector);
go

SELECT CAST('[NaN,1]' as vector);
go

SELECT CAST('[Infinity,1]' as vector);
go

SELECT CAST('[-Infinity,1]' as vector);
go

SELECT CAST('[1.5e38,-1.5e38]' as vector);
go

SELECT CAST('[1.5e+38,-1.5e+38]' as vector);
go

SELECT CAST('[1.5e-38,-1.5e-38]' as vector);
go

SELECT CAST('[4e38,1]' as vector);
go

SELECT CAST('[1,2,3' as vector);
go

SELECT CAST('[1,2,3]9' as vector);
go

SELECT CAST('1,2,3' as vector);
go

SELECT CAST('' as vector);
go

SELECT CAST('[' as vector);
go

SELECT CAST('[,' as vector);
go

SELECT CAST('[]' as vector);
go

SELECT CAST('[1,]' as vector);
go

SELECT CAST('[1a]' as vector);
go

SELECT CAST('[1,,3]' as vector);
go

SELECT CAST('[1, ,3]' as vector);
go

SELECT CAST('[1,2,3]' as vector(2));
go

select set_config('babelfishpg_tsql.explain_costs', 'on', false);
go
select set_config('babelfishpg_tsql.explain_timing', 'on', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'on', false);
go