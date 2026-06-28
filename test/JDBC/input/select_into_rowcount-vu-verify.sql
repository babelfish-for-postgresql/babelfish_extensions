-- Multiple rows into permanent table
SELECT * INTO select_into_rowcount_vu_verify_t1 FROM select_into_rowcount_vu_prepare_src;
GO

-- Single row into permanent table
SELECT * INTO select_into_rowcount_vu_verify_t2 FROM select_into_rowcount_vu_prepare_src WHERE c1 = 1;
GO

-- Zero rows into permanent table
SELECT * INTO select_into_rowcount_vu_verify_t3 FROM select_into_rowcount_vu_prepare_src WHERE 1 = 0;
GO

-- Multiple rows into temp table
SELECT * INTO #select_into_rowcount_vu_verify_t4 FROM select_into_rowcount_vu_prepare_src;
GO

-- Single row into temp table
SELECT * INTO #select_into_rowcount_vu_verify_t5 FROM select_into_rowcount_vu_prepare_src WHERE c1 = 2;
GO

-- Zero rows into temp table
SELECT * INTO #select_into_rowcount_vu_verify_t6 FROM select_into_rowcount_vu_prepare_src WHERE 1 = 0;
GO

-- Select specific columns
SELECT c1 INTO select_into_rowcount_vu_verify_t7 FROM select_into_rowcount_vu_prepare_src;
GO

-- Select specific columns into temp table
SELECT c2 INTO #select_into_rowcount_vu_verify_t8 FROM select_into_rowcount_vu_prepare_src WHERE c1 > 1;
GO

-- From subquery
SELECT * INTO select_into_rowcount_vu_verify_t9 FROM (SELECT 1 AS c1 UNION ALL SELECT 2 UNION ALL SELECT 3) t;
GO

-- From subquery into temp table
SELECT * INTO #select_into_rowcount_vu_verify_t10 FROM (SELECT 'a' AS val UNION ALL SELECT 'b') t;
GO

-- Single row from subquery
SELECT * INTO #select_into_rowcount_vu_verify_t11 FROM (SELECT 42 AS num) t;
GO

-- Verify @@ROWCOUNT is correct after SELECT INTO
SELECT * INTO #select_into_rowcount_vu_verify_t12 FROM select_into_rowcount_vu_prepare_src;
SELECT @@ROWCOUNT;
GO
