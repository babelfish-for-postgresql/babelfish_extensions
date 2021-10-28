-- default value was changed from 'strict' to 'ignore'.
-- to minimize touching test, test 'strict' first.
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

-- simple unsupported query but accepted in backend parser. should throw an error.
SET ANSI_PADDING OFF;
GO

SET ANSI_WARNINGS OFF;
GO

SET ARITHABORT OFF;
GO

SET ARITHIGNORE ON;
GO

SET NUMERIC_ROUNDABORT ON;
GO

SET NOEXEC ON;
GO

SET SHOWPLAN_ALL ON;
GO

SET SHOWPLAN_TEXT ON;
GO

SET SHOWPLAN_XML ON;
GO

SET STATISTICS IO ON;
GO

SET OFFSETS SELECT ON;
GO

SET DATEFORMAT dmy;
GO

SET DEADLOCK_PRIORITY 0;
GO

SET LOCK_TIMEOUT 10;
GO

SET CONTEXT_INFO 0;
GO

SET LANGUAGE 'english'
GO

-- one supported + one unsupported
SET ANSI_NULLS, ANSI_PADDING OFF;
GO
select current_setting('babelfishpg_tsql.ansi_nulls');
GO
SET ANSI_NULLS ON;
GO

SET ANSI_NULLS, STATISTICS IO OFF;
GO
select current_setting('babelfishpg_tsql.ansi_nulls'); -- should not be chagned
GO

-- two unsupported
SET ANSI_PADDING, FORCEPLAN ON;
GO

SET STATISTICS IO, OFFSETS SELECT ON;
GO

-- escape_hatch_session_settings
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO

SET ANSI_PADDING OFF;
GO
select current_setting('babelfishpg_tsql.ansi_padding');
GO

SET ANSI_WARNINGS OFF;
GO
select current_setting('babelfishpg_tsql.ansi_warnings');
GO

SET ARITHABORT OFF;
GO
select current_setting('babelfishpg_tsql.arithabort');
GO

SET ARITHIGNORE ON;
GO
select current_setting('babelfishpg_tsql.arithignore');
GO

SET NUMERIC_ROUNDABORT ON;
GO
select current_setting('babelfishpg_tsql.numeric_roundabort');
GO

SET NOEXEC ON;
GO
select current_setting('babelfishpg_tsql.noexec');
GO

SET SHOWPLAN_ALL ON;
GO
select current_setting('babelfishpg_tsql.showplan_all');
GO

SET SHOWPLAN_TEXT ON;
GO
select current_setting('babelfishpg_tsql.showplan_text');
GO

SET SHOWPLAN_XML ON;
GO
select current_setting('babelfishpg_tsql.showplan_xml');
GO

-- these statement will be ignored silently
SET STATISTICS IO ON;
GO
SET OFFSETS SELECT ON;
GO
SET DATEFORMAT dmy;
GO
SET DEADLOCK_PRIORITY 0;
GO
SET LOCK_TIMEOUT 10;
GO
SET CONTEXT_INFO 0;
GO
SET LANGUAGE 'english';
GO

-- one supported + one unsupported
SET ANSI_NULLS, ANSI_PADDING OFF;
GO
select current_setting('babelfishpg_tsql.ansi_nulls'); -- should be changed
GO
SET ANSI_NULLS ON;
GO

SET ANSI_NULLS, STATISTICS IO OFF;
GO
select current_setting('babelfishpg_tsql.ansi_nulls'); -- should not be chagned
GO
SET ANSI_NULLS ON;
GO

-- two unsupported
SET ANSI_PADDING, FORCEPLAN ON;
GO

SET STATISTICS IO, OFFSETS SELECT ON;
GO


EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

-- simple unsupported query which backend parser can't understand. should throw an error with nice error message
ALTER DATABASE blah SET ANSI_PADDING OFF;
GO

-- unsupported query in a batch. execution should be aborted.
DECLARE @v varchar(20);
SET ANSI_PADDING OFF; -- error
SET @v = 'SHOULD NOT BE SHOWN';
SELECT @v;
GO

DECLARE @v varchar(20);
ALTER DATABASE blah SET ANSI_PADDING OFF; -- error
SET @v = 'SHOULD NOT BE SHOWN';
SELECT @v;
GO

-- escape hatch: storage_options
-- 'ignore' is default

CREATE TABLE t_unsupported_fg1(a int) ON [primary];
GO
DROP TABLE t_unsupported_fg1
GO

CREATE TABLE t_unsupported_fg2(a int) TEXTIMAGE_ON [primary];
GO
DROP TABLE t_unsupported_fg2
GO

CREATE TABLE t_unsupported_fg3(a int) FILESTREAM_ON [primary];
GO
DROP TABLE t_unsupported_fg3
GO

CREATE TABLE t_unsupported_fg4(a int) ON [primary] TEXTIMAGE_ON [primary];
GO
DROP TABLE t_unsupported_fg4
GO

CREATE TABLE t_unsupported_fg5(a int);
GO
CREATE INDEX t_unsupported_fg5_i1 ON t_unsupported_fg5(a) ON [primary];
GO
DROP TABLE t_unsupported_fg5;
GO

CREATE TABLE t_unsupported_fg6(a int);
GO
ALTER TABLE t_unsupported_fg6 SET (FILESTREAM_ON = [primary]);
GO
DROP TABLE t_unsupported_fg6;
GO

CREATE TABLE t_unsupported_fg7(a int) ON "default";
GO
DROP TABLE t_unsupported_fg7;
GO

CREATE TABLE t_unsupported_fg8(a int) FILESTREAM_ON [primary];
GO
DROP TABLE t_unsupported_fg8
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_fg1(a int) ON [primary];
GO

CREATE TABLE t_unsupported_fg2(a int) TEXTIMAGE_ON [primary];
GO

CREATE TABLE t_unsupported_fg3(a int) FILESTREAM_ON [primary];
GO

CREATE TABLE t_unsupported_fg4(a int) ON [primary] TEXTIMAGE_ON [primary];
GO

CREATE TABLE t_unsupported_fg5(a int);
GO
CREATE INDEX t_unsupported_fg5_i1 ON t_unsupported_fg5(a) ON [primary];
GO
DROP TABLE t_unsupported_fg5;
GO

CREATE TABLE t_unsupported_fg6(a int);
GO
ALTER TABLE t_unsupported_fg6 SET (FILESTREAM_ON = [primary]);
GO
DROP TABLE t_unsupported_fg6;
GO

CREATE TABLE t_unsupported_fg7(a int) ON "default";
GO

CREATE TABLE t_unsupported_fg8(a int) FILESTREAM_ON [primary];
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO

-- escape hatch: storage_on_partition.
-- 'strict' is default

CREATE TABLE t_unsupported_sop1(a int) ON partition(a);
GO

CREATE TABLE t_unsupported_sop2(a int) FILESTREAM_ON partition(a);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_on_partition', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_sop1(a int) ON partition(a);
GO
DROP TABLE t_unsupported_sop1;
GO

CREATE TABLE t_unsupported_sop2(a int) FILESTREAM_ON partition(a);
GO
DROP TABLE t_unsupported_sop2
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_on_partition', 'strict', 'false')
GO


-- escape hatch: database_misc_options
-- 'ignore is default

CREATE DATABASE db_unsupported1 CONTAINMENT = NONE;
GO
DROP DATABASE db_unsupported1;
GO

CREATE DATABASE db_unsupported2 CONTAINMENT = PARTIAL;
GO
DROP DATABASE db_unsupported2;
GO

CREATE DATABASE db_unsupported3 WITH DB_CHAINING ON;
GO
DROP DATABASE db_unsupported3;
GO

CREATE DATABASE db_unsupported4 WITH TRUSTWORTHY OFF;
GO
DROP DATABASE db_unsupported4;
GO

CREATE DATABASE db_unsupported5 CONTAINMENT = NONE WITH DB_CHAINING ON, DEFAULT_LANGUAGE = us_english, TRUSTWORTHY OFF;
GO
DROP DATABASE db_unsupported5;
GO

CREATE DATABASE db_unsupported6 WITH PERSISTENT_LOG_BUFFER = ON (DIRECTORY_NAME = '/tmp');
GO
DROP DATABASE db_unsupported6;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_database_misc_options', 'strict', 'false')
GO

CREATE DATABASE db_unsupported1 CONTAINMENT = NONE;
GO

CREATE DATABASE db_unsupported2 CONTAINMENT = PARTIAL;
GO

CREATE DATABASE db_unsupported3 WITH DB_CHAINING ON;
GO

CREATE DATABASE db_unsupported4 WITH TRUSTWORTHY OFF;
GO

CREATE DATABASE db_unsupported5 CONTAINMENT = NONE WITH DB_CHAINING ON, DEFAULT_LANGUAGE = us_english, TRUSTWORTHY OFF;
GO

CREATE DATABASE db_unsupported6 WITH PERSISTENT_LOG_BUFFER = ON (DIRECTORY_NAME = '/tmp');
GO
DROP DATABASE db_unsupported6;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_database_misc_options', 'ignore', 'false')
GO


-- escape hatch: language_non_english
-- default is 'strict'

CREATE DATABASE db_unsupported_l1 WITH DEFAULT_LANGUAGE = us_english;
GO
DROP DATABASE db_unsupported_l1;
GO

CREATE DATABASE db_unsupported_l2 WITH DEFAULT_LANGUAGE = English;
GO
DROP DATABASE db_unsupported_l2;
GO

CREATE DATABASE db_unsupported_l3 WITH DEFAULT_LANGUAGE = Deutsch;
GO

CREATE LOGIN u_unsupported with password='12345678', default_language=english;
GO

ALTER LOGIN u_unsupported with default_language=english;
GO

ALTER LOGIN u_unsupported with default_language=spanish;
GO

DROP LOGIN u_unsupported;
GO

CREATE LOGIN u_unsupported_2 with password='12345678', default_language=spanish;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_language_non_english', 'ignore', 'false')
GO

CREATE DATABASE db_unsupported_l1 WITH DEFAULT_LANGUAGE = us_english;
GO
DROP DATABASE db_unsupported_l1;
GO

CREATE DATABASE db_unsupported_l2 WITH DEFAULT_LANGUAGE = English;
GO
DROP DATABASE db_unsupported_l2;
GO

CREATE DATABASE db_unsupported_l3 WITH DEFAULT_LANGUAGE = Deutsch;
GO
DROP DATABASE db_unsupported_l3;
GO

CREATE LOGIN u_unsupported with password='12345678', default_language=english;
GO

ALTER LOGIN u_unsupported with default_language=english;
GO

ALTER LOGIN u_unsupported with default_language=spanish;
GO

DROP LOGIN u_unsupported;
GO

CREATE LOGIN u_unsupported_2 with password='12345678', default_language=spanish;
GO

DROP LOGIN u_unsupported_2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_language_non_english', 'strict', 'false')
GO


-- escape hatch: fulltext
-- 'strict' is default

CREATE TABLE t_unsupported_ft (a text);
GO

CREATE FULLTEXT INDEX ON t_unsupported_ft(a) KEY INDEX ix_unsupported_ft;
GO

DROP TABLE t_unsupported_ft;
GO

CREATE DATABASE db_unsupported_ft WITH DEFAULT_FULLTEXT_LANGUAGE = English;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_ft (a text);
GO

CREATE FULLTEXT INDEX ON t_unsupported_ft(a) KEY INDEX ix_unsupported_ft;
GO

DROP TABLE t_unsupported_ft;
GO

CREATE DATABASE db_unsupported_ft WITH DEFAULT_FULLTEXT_LANGUAGE = English;
GO
DROP DATABASE db_unsupported_ft;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO


-- escape hatch: schemabinding.
-- 'ignore' is by default. test if an error is thrown in strict mode if it is not explicitly given
SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_function', 'strict', 'false')
GO
CREATE FUNCTION f_unsupported_1 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
GO
CREATE FUNCTION f_unsupported_2 (@v int) RETURNS TABLE AS RETURN select @v+1 as a;
GO
CREATE FUNCTION f_unsupported_3 (@v int) RETURNS INT WITH RETURNS NULL ON NULL INPUT AS BEGIN RETURN @v+1 END;
GO
SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_function', 'ignore', 'false')
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_procedure', 'strict', 'false')
GO
CREATE PROCEDURE p_unsupported_1 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO
SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_procedure', 'ignore', 'false')
GO

CREATE TABLE t_unsupported (a int);
INSERT INTO t_unsupported values (1);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_view', 'strict', 'false')
GO
CREATE VIEW v_unsupported AS SELECT * FROM t_unsupported;
GO
SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_view', 'ignore', 'false')
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_trigger', 'strict', 'false')
GO
CREATE TRIGGER tr_unsupported on t_unsupported AFTER INSERT AS print 'triggered';
GO
SELECT set_config('babelfishpg_tsql.escape_hatch_schemabinding_trigger', 'ignore', 'false')
GO

DROP table t_unsupported;
GO


-- escape hatch escape_hatch_index_clustering
-- 'ignore' is default

CREATE TABLE t_unsupported_ic1(a int, b int);
GO
CREATE CLUSTERED INDEX i_unsupported_ic11 on t_unsupported_ic1(a);
GO
CREATE NONCLUSTERED INDEX i_unsupported_ic12 on t_unsupported_ic1(b);
GO
DROP TABLE t_unsupported_ic1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_index_clustering', 'strict', 'false')
GO

CREATE TABLE t_unsupported_ic1(a int, b int);
GO
CREATE CLUSTERED INDEX i_unsupported_ic11 on t_unsupported_ic1(a);
GO
CREATE NONCLUSTERED INDEX i_unsupported_ic12 on t_unsupported_ic1(b);
GO
DROP TABLE t_unsupported_ic1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_index_clustering', 'ignore', 'false')
GO

-- BABEL-1484
-- escape hatch escape_hatch_unique_constraint
-- 'strict' is default
-- Test UNIQUE CONSTRAINT is not allowed on nullable column
-- this includes: create unique index, alter table add constraint unique
-- and create table with column constraint
CREATE TABLE t_unsupported_uc1(a int, b int NOT NULL, c int NOT NULL);
GO
CREATE UNIQUE INDEX i_unsupported_uc1 on t_unsupported_uc1(a);
GO
ALTER TABLE t_unsupported_uc1 ADD CONSTRAINT UQ_a UNIQUE (a);
GO
CREATE TABLE t_unsupported_uc2(a int UNIQUE, b int);
GO

-- Test UNIQUE CONSTRAINT is allowed on NOT NULL column
CREATE UNIQUE INDEX i_unsupported_uc1 on t_unsupported_uc1(b);
GO
ALTER TABLE t_unsupported_uc1 ADD CONSTRAINT UQ_c UNIQUE (c);
GO
CREATE TABLE t_unsupported_uc2(a int UNIQUE NOT NULL, b int NOT NULL UNIQUE);
GO

DROP TABLE t_unsupported_uc1;
DROP TABLE t_unsupported_uc2;
GO

-- test UNIQUE INDEX/CONSTRAINT is allowed on nullable column
-- if escap_hatch_unique_constraint is set to ignore
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
GO

CREATE TABLE t_unsupported_uc1(a int, b varchar(10));
GO

CREATE UNIQUE INDEX i_unsupported_uc1 on t_unsupported_uc1(b);
GO

ALTER TABLE t_unsupported_uc1 ADD CONSTRAINT UQ_a UNIQUE (a);
GO

CREATE TABLE t_unsupported_uc2(a int UNIQUE, b varchar(10) UNIQUE);
GO

DROP TABLE t_unsupported_uc1
DROP TABLE t_unsupported_uc2
GO

-- escape hatch escape_hatch_index_columnstore
-- 'strict' is default

CREATE TABLE t_unsupported_cs1(a int, b int);
GO
CREATE COLUMNSTORE INDEX i_unsupported_cs1 on t_unsupported_cs1(a);
GO
DROP TABLE t_unsupported_cs1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_index_columnstore', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_cs1(a int, b int);
GO
CREATE COLUMNSTORE INDEX i_unsupported_cs1 on t_unsupported_cs1(a);
GO
DROP TABLE t_unsupported_cs1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_index_columnstore', 'strict', 'false')
GO


-- escape hatch escape_hatch_for_replication
-- 'strict' is default

CREATE TABLE t_unsupported_fr1(a int FOR REPLICATION);
GO

CREATE TABLE t_unsupported_fr2(a int);
GO
ALTER TABLE t_unsupported_fr2 ADD b int NOT FOR REPLICATION;
GO
DROP TABLE t_unsupported_fr2;
GO

CREATE PROCEDURE p_unsupported_fr1 (@v int) FOR REPLICATION AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO

CREATE TABLE t_unsupported_fr3(a int);
GO
CREATE TRIGGER tr_unsupported_fr3 on t_unsupported_fr3 AFTER INSERT NOT FOR REPLICATION AS print 'triggered';
GO
DROP TABLE t_unsupported_fr3;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_for_replication', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_fr1(a int FOR REPLICATION);
GO
DROP TABLE t_unsupported_fr1;
GO

CREATE TABLE t_unsupported_fr2(a int);
GO
ALTER TABLE t_unsupported_fr2 ADD b int NOT FOR REPLICATION;
GO
DROP TABLE t_unsupported_fr2;
GO

CREATE PROCEDURE p_unsupported_fr1 (@v int) FOR REPLICATION AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO
DROP PROCEDURE p_unsupported_fr1;
GO

CREATE TABLE t_unsupported_fr3(a int);
GO
CREATE TRIGGER tr_unsupported_fr3 on t_unsupported_fr3 AFTER INSERT NOT FOR REPLICATION AS print 'triggered';
GO
DROP TABLE t_unsupported_fr3;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_for_replication', 'strict', 'false')
GO


-- escape hatch escape_hatch_rowguidcol_column
-- 'ignore' is default

CREATE TABLE t_unsupported_gc1(a int ROWGUIDCOL);
GO
DROP TABLE t_unsupported_gc1;
GO

CREATE TABLE t_unsupported_gc2(a int);
GO
ALTER TABLE t_unsupported_gc2 ADD b int ROWGUIDCOL;
GO
DROP TABLE t_unsupported_gc2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_rowguidcol_column', 'strict', 'false')
GO

CREATE TABLE t_unsupported_gc1(a int ROWGUIDCOL);
GO

CREATE TABLE t_unsupported_gc2(a int);
GO
ALTER TABLE t_unsupported_gc2 ADD b int ROWGUIDCOL;
GO
DROP TABLE t_unsupported_gc2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_rowguidcol_column', 'ignore', 'false')
GO


-- escape hatch escape_hatch_sparse_column (incorporated with storage_options)
-- 'ignore' is default

CREATE TABLE t_unsupported_sc1(a int SPARSE, b int);
GO
DROP TABLE t_unsupported_sc1
GO

CREATE TABLE t_unsupported_sc2(a int);
GO
ALTER TABLE t_unsupported_sc2 ADD b int SPARSE;
GO
DROP TABLE t_unsupported_sc2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_sc1(a int SPARSE, b int);
GO

CREATE TABLE t_unsupported_sc2(a int);
GO
ALTER TABLE t_unsupported_sc2 ADD b int SPARSE;
GO
DROP TABLE t_unsupported_sc2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO


-- escape hatch: filestream. (incorporated into storage_options)
-- 'ignore' is default

CREATE TABLE t_unsupported_fs1(a int FILESTREAM, b int);
GO
DROP TABLE t_unsupported_fs1
GO

CREATE TABLE t_unsupported_fs2(a int);
GO
ALTER TABLE t_unsupported_fs2 ADD b int FILESTREAM;
GO
DROP TABLE t_unsupported_fs2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_fs1(a int FILESTREAM, b int);
GO

CREATE TABLE t_unsupported_fs2(a int);
GO
ALTER TABLE t_unsupported_fs2 ADD b int FILESTREAM;
GO
DROP TABLE t_unsupported_fs2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO


-- escape hatch: escape_hatch_fillfactor. (incorporated with storage_options)
-- 'ignore' is default

CREATE TABLE t_unsupported_ff1(a int, primary key(a) with fillfactor=50);
GO
DROP TABLE t_unsupported_ff1
GO

CREATE TABLE t_unsupported_ff2(a int primary key with fillfactor=50);
GO
DROP TABLE t_unsupported_ff2
GO

CREATE TABLE t_unsupported_ff3(a int);
GO
ALTER TABLE t_unsupported_ff3 ADD PRIMARY KEY(a) with fillfactor=50;
GO
DROP TABLE t_unsupported_ff3;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_ff1(a int, primary key(a) with fillfactor=50);
GO

CREATE TABLE t_unsupported_ff2(a int primary key with fillfactor=50);
GO

CREATE TABLE t_unsupported_ff3(a int);
GO
ALTER TABLE t_unsupported_ff3 ADD PRIMARY KEY(a) with fillfactor=50;
GO
DROP TABLE t_unsupported_ff3;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO


-- escape hatch: escape_hatch_storage_options (especially index option).
-- 'ignore' is default

CREATE TABLE t_unsupported_so1(a int, primary key(a) with data_compression=none);
GO
DROP TABLE t_unsupported_so1
GO

CREATE TABLE t_unsupported_so2(a int, primary key(a) with pad_index=on);
GO
DROP TABLE t_unsupported_so2
GO

CREATE TABLE t_unsupported_so3(a int, primary key(a) with ignore_dup_key=on);
GO
DROP TABLE t_unsupported_so3
GO

CREATE TABLE t_unsupported_so4(a int, primary key(a) with STATISTICS_NORECOMPUTE=on);
GO
DROP TABLE t_unsupported_so4
GO

CREATE TABLE t_unsupported_so5(a int, primary key(a) with STATISTICS_INCREMENTAL=on);
GO
DROP TABLE t_unsupported_so5
GO

CREATE TABLE t_unsupported_so6(a int, primary key(a) with DROP_EXISTING=on);
GO

CREATE TABLE t_unsupported_so7(a int, primary key(a) with ONLINE=on);
GO

CREATE TABLE t_unsupported_so8(a int, primary key(a) with RESUMABLE=on, ONLINE=on);
GO

CREATE TABLE t_unsupported_so9(a int, primary key(a) with (MAX_DURATION=60, ONLINE=on));
GO

CREATE TABLE t_unsupported_so10(a int, primary key(a) with (ALLOW_ROW_LOCKS=on));
GO
DROP TABLE t_unsupported_so10;
GO

CREATE TABLE t_unsupported_so11(a int, primary key(a) with (ALLOW_PAGE_LOCKS=on));
GO
DROP TABLE t_unsupported_so11;
GO

CREATE TABLE t_unsupported_so12(a int, primary key(a) with (OPTIMIZE_FOR_SEQUENTIAL_KEY=on));
GO
DROP TABLE t_unsupported_so12;
GO

CREATE TABLE t_unsupported_so13(a int, primary key(a) with (MAXDOP=40));
GO
DROP TABLE t_unsupported_so13;
GO

-- multiple options
CREATE TABLE t_unsupported_so14(a int, primary key(a) with data_compression=none, fillfactor=50);
GO
DROP TABLE t_unsupported_so14
GO

-- create index
CREATE TABLE t_unsupported_so15(a int);
GO
CREATE INDEX i_unsupported_so15 on t_unsupported_so15(a) with data_compression=none;
GO
DROP TABLE t_unsupported_so15
GO

-- create database with filestream
CREATE DATABASE db_unsupported1 WITH FILESTREAM (DIRECTORY_NAME = '/tmp')
GO
DROP DATABASE db_unsupported1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_so1(a int, primary key(a) with data_compression=none);
GO

CREATE TABLE t_unsupported_so2(a int, primary key(a) with pad_index=on);
GO

CREATE TABLE t_unsupported_so3(a int, primary key(a) with ignore_dup_key=on);
GO

CREATE TABLE t_unsupported_so4(a int, primary key(a) with STATISTICS_NORECOMPUTE=on);
GO

CREATE TABLE t_unsupported_so5(a int, primary key(a) with STATISTICS_INCREMENTAL=on);
GO

CREATE TABLE t_unsupported_so6(a int, primary key(a) with DROP_EXISTING=on);
GO

CREATE TABLE t_unsupported_so7(a int, primary key(a) with ONLINE=on);
GO

CREATE TABLE t_unsupported_so8(a int, primary key(a) with RESUMABLE=on, ONLINE=on);
GO

CREATE TABLE t_unsupported_so9(a int, primary key(a) with (MAX_DURATION=60, ONLINE=on));
GO

CREATE TABLE t_unsupported_so10(a int, primary key(a) with (ALLOW_ROW_LOCKS=on));
GO

CREATE TABLE t_unsupported_so11(a int, primary key(a) with (ALLOW_PAGE_LOCKS=on));
GO

CREATE TABLE t_unsupported_so12(a int, primary key(a) with (OPTIMIZE_FOR_SEQUENTIAL_KEY=on));
GO

CREATE TABLE t_unsupported_so13(a int, primary key(a) with (MAXDOP=40));
GO

-- multiple options
CREATE TABLE t_unsupported_so14(a int, primary key(a) with data_compression=none, fillfactor=50);
GO

-- create index
CREATE TABLE t_unsupported_so15(a int);
GO
CREATE INDEX i_unsupported_so15 on t_unsupported_so15(a) with data_compression=none;
GO
DROP TABLE t_unsupported_so15
GO

-- create database with filestream
CREATE DATABASE db_unsupported1 WITH FILESTREAM (DIRECTORY_NAME = '/tmp')
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO


-- escape hatch: escape_hatch_nocheck_add_constraint.
-- 'strict' is default

CREATE TABLE t_unsupported_cac1(a int, b int);
GO
ALTER TABLE t_unsupported_cac1 WITH CHECK ADD constraint chk1 check (a > 0)
GO
ALTER TABLE t_unsupported_cac1 WITH NOCHECK ADD constraint chk2 check (b < 0)
GO
DROP TABLE t_unsupported_cac1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_nocheck_add_constraint', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_cac1(a int, b int);




SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
GO

CREATE TABLE t_unsupported_so1(a int, primary key(a) with data_compression=none);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
GO


-- escape hatch: escape_hatch_nocheck_add_constraint.
-- 'strict' is default

CREATE TABLE t_unsupported_cac1(a int, b int);
GO
ALTER TABLE t_unsupported_cac1 WITH CHECK ADD constraint chk1 check (a > 0)
GO
ALTER TABLE t_unsupported_cac1 WITH NOCHECK ADD constraint chk2 check (b < 0)
GO
DROP TABLE t_unsupported_cac1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_nocheck_add_constraint', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_cac1(a int, b int);
GO
ALTER TABLE t_unsupported_cac1 WITH CHECK ADD constraint chk1 check (a > 0)
GO
ALTER TABLE t_unsupported_cac1 WITH NOCHECK ADD constraint chk2 check (b < 0)
GO
INSERT INTO t_unsupported_cac1 VALUES (0, 0);
GO
DROP TABLE t_unsupported_cac1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_nocheck_add_constraint', 'strict', 'false')
GO


-- escape hatch: escape_hatch_nocheck_existing_constraint.
-- 'strict' is default

CREATE TABLE t_unsupported_cec1(a int, b int);
GO
INSERT INTO t_unsupported_cec1 values (0, 0);
GO
ALTER TABLE t_unsupported_cec1 ADD constraint chk1 check (a > 0)
GO
ALTER TABLE t_unsupported_cec1 CHECK constraint chk1
GO
DROP TABLE t_unsupported_cec1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_nocheck_existing_constraint', 'ignore', 'false')
GO

CREATE TABLE t_unsupported_cec1(a int, b int);
GO
INSERT INTO t_unsupported_cec1 values (0, 0);
GO
ALTER TABLE t_unsupported_cec1 ADD constraint chk1 check (a > 0)
GO
ALTER TABLE t_unsupported_cec1 CHECK constraint chk1
GO
DROP TABLE t_unsupported_cec1
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_nocheck_existing_constraint', 'strict', 'false')
GO

-- escape hatch: escape_hatch_constraint_name_for_default.
-- 'ignore' is deafult

CREATE TABLE t_unsupported_cd1(a int, b int);
GO
ALTER TABLE t_unsupported_cd1 ADD CONSTRAINT d1 DEFAULT 99 FOR a;
GO
INSERT INTO t_unsupported_cd1(b) VALUES (1);
GO
SELECT * FROM t_unsupported_cd1;
GO
DROP TABLE t_unsupported_cd1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_constraint_name_for_default', 'strict', 'false')
GO

CREATE TABLE t_unsupported_cd1(a int, b int);
GO
ALTER TABLE t_unsupported_cd1 ADD CONSTRAINT d1 DEFAULT 99 FOR a;
GO
INSERT INTO t_unsupported_cd1(b) VALUES (1);
GO
SELECT * FROM t_unsupported_cd1;
GO
DROP TABLE t_unsupported_cd1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_constraint_name_for_default', 'ignore', 'false')
GO

-- escape hatch: table_hints
-- 'ignore' is default.
-- we have separate test already so briefly check simple cases here.

CREATE TABLE t_unsupported_th1(a int);
GO
INSERT INTO t_unsupported_th1 WITH (INDEX=i1) VALUES (1), (2);
GO
UPDATE t_unsupported_th1 WITH (INDEX=i1) SET a = 3 WHERE a=2;
GO
DELETE FROM t_unsupported_th1 WITH (INDEX=i1) WHERE a = 1;
GO
SELECT * FROM t_unsupported_th1 WITH (INDEX=i1);
GO
DROP TABLE t_unsupported_th1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_table_hints', 'strict', 'false')
GO

CREATE TABLE t_unsupported_th1(a int);
GO
INSERT INTO t_unsupported_th1 WITH (INDEX=i1) VALUES (1), (2);
GO
UPDATE t_unsupported_th1 WITH (INDEX=i1) SET a = 3 WHERE a=2;
GO
DELETE FROM t_unsupported_th1 WITH (INDEX=i1) WHERE a = 1;
GO
SELECT * FROM t_unsupported_th1 WITH (INDEX=i1);
GO
DROP TABLE t_unsupported_th1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_table_hints', 'ignore', 'false')
GO


-- escape hatch: query_hints
-- 'ignore' is default.

CREATE TABLE t_unsupported_qh1(a int);
GO
INSERT INTO t_unsupported_qh1 VALUES (1), (2) OPTION (MERGE JOIN)
GO
UPDATE t_unsupported_qh1 SET a = 3 WHERE a=2 OPTION (HASH GROUP);
GO
DELETE FROM t_unsupported_qh1 WHERE a = 1 OPTION (CONCAT UNION);
GO
SELECT * FROM t_unsupported_qh1 OPTION (FORCE ORDER);
GO
DROP TABLE t_unsupported_qh1;
GO


SELECT set_config('babelfishpg_tsql.escape_hatch_query_hints', 'strict', 'false')
GO

CREATE TABLE t_unsupported_qh1(a int);
GO
INSERT INTO t_unsupported_qh1 VALUES (1), (2) OPTION (MERGE JOIN)
GO
UPDATE t_unsupported_qh1 SET a = 3 WHERE a=2 OPTION (HASH GROUP);
GO
DELETE FROM t_unsupported_qh1 WHERE a = 1 OPTION (CONCAT UNION);
GO
SELECT * FROM t_unsupported_qh1 OPTION (FORCE ORDER);
GO
DROP TABLE t_unsupported_qh1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_query_hints', 'ignore', 'false')
GO


-- escape hatch: join_hints
-- 'ignore' is default.

CREATE TABLE t_unsupported_jh1(a int);
CREATE TABLE t_unsupported_jh2(a int);
GO
INSERT INTO t_unsupported_jh1 values (1), (2);
INSERT INTO t_unsupported_jh2 values (1), (3);
GO
SELECT * FROM t_unsupported_jh1 t1 INNER HASH JOIN t_unsupported_jh2 t2 ON t1.a=t2.a;
GO
DROP TABLE t_unsupported_jh1;
DROP TABLE t_unsupported_jh2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_join_hints', 'strict', 'false')
GO

CREATE TABLE t_unsupported_jh1(a int);
CREATE TABLE t_unsupported_jh2(a int);
GO
INSERT INTO t_unsupported_jh1 values (1), (2);
INSERT INTO t_unsupported_jh2 values (1), (3);
GO
SELECT * FROM t_unsupported_jh1 t1 INNER HASH JOIN t_unsupported_jh2 t2 ON t1.a=t2.a;
GO
DROP TABLE t_unsupported_jh1;
DROP TABLE t_unsupported_jh2;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_join_hints', 'ignore', 'false')
GO


-- test of sp_babelfish_configure

EXEC sp_babelfish_configure;
GO

-- short name
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_function';
GO

-- full name
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_function';
GO

-- with wildcard
EXEC sp_babelfish_configure '%';
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.%';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%';
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_%';
GO

-- set
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_function', 'strict';
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_function';
GO

-- now should throw an error
CREATE FUNCTION f_unsupported_1 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
GO

-- set with wildcard
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_%', 'strict';
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_%';
GO

-- should throw an error
CREATE PROCEDURE p_unsupported_1 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO

-- reset
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_%', 'ignore';
GO

-- same tests with no prefix
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_function', 'strict';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_function';
GO

-- now should throw an error
CREATE FUNCTION f_unsupported_1 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
GO

-- set with wildcard
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%', 'strict';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%';
GO

-- should throw an error
CREATE PROCEDURE p_unsupported_1 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO

-- reset
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%', 'ignore';
GO

-- server option
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%', 'strict', 'server';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%';
GO
select config_value from (select unnest(setconfig) config_value from pg_db_role_setting) t where config_value like '%escape_hatch_schemabinding_%' order by config_value;
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_function', 'ignore', 'server';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%';
GO
select config_value from (select unnest(setconfig) config_value from pg_db_role_setting) t where config_value like '%escape_hatch_schemabinding_%' order by config_value;
GO

-- reset
EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%', 'ignore', 'server';
GO

EXEC sp_babelfish_configure 'escape_hatch_schemabinding_%';
GO
select config_value from (select unnest(setconfig) config_value from pg_db_role_setting) t where config_value like '%escape_hatch_schemabinding_%' order by config_value;
GO

-- non-existing guc
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_XX', 'ignore';
GO

-- invalid server option
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_%', 'ignore', 'invalid';
GO

-- test automatically generated message for unsupported DDL
CREATE PARTITION FUNCTION f_unsupported_1(datetime) AS RANGE RIGHT FOR VALUES (N'2017-07-11T00:00:00.000', N'2017-07-12T00:00:00.000', N'2017-07-13T00:00:00.000');
GO

ALTER AUTHORIZATION ON a1 TO SCHEMA OWNER;
GO

-- kill (BABEL-2159)
KILL 1;
GO

-- apply
SELECT * FROM t1 CROSS APPLY (SELECT * FROM Employee E WHERE E.DepartmentID = D.DepartmentID) A
GO

-- alter view (BABEL-2017)
CREATE TABLE t_babel_2017(a int, b int);
GO
CREATE VIEW v_babel_2017 AS SELECT * FROM t_babel_2017;
GO
ALTER VIEW v_babel_2017 AS SELECT a FROM t_babel_2017;
GO
CREATE OR ALTER VIEW v_babel_2017 AS SELECT b FROM t_babel_2017;
GO
DROP VIEW v_babel_2017;
GO
DROP TABLE t_babel_2017;
GO


-- alter trigger (2110)
CREATE TABLE t2110a(c int);
CREATE TABLE t2110b(c int);
GO
CREATE TRIGGER trigger2110 ON t2110a FOR INSERT AS SELECT * FROM t2110a;
GO
ALTER TRIGGER trigger2110 ON t2110b FOR INSERT AS SELECT * FROM t2110a;
GO
DROP TABLE t2110a, t2110b;
GO


-- alter schema transfer (33144)
CREATE SCHEMA s33144;
GO
CREATE TABLE t33144(a int);
GO
ALTER SCHEMA s33144 TRANSFER t33144;
GO
DROP TABLE t33144;
GO
DROP SCHEMA s33144;
GO


-- alter table add PERSISTED (4919)
CREATE TABLE t4919(c1 int, c2 varchar(1));
GO
ALTER TABLE t4919 ALTER COLUMN c2 varchar(1) ADD PERSISTED;
GO
DROP TABLE t4919;
GO


-- PIVOT (265, 488)
CREATE TABLE t265 (c1 VARCHAR(50), c2 VARCHAR(50));
GO
SELECT * FROM (SELECT c1, c2 FROM t265) AS p PIVOT (COUNT(c1) FOR c2 IN (c1)) AS pv;
GO
DROP TABLE t265;
GO

CREATE TABLE t488(id text);
GO
SELECT * FROM (SELECT id from t488) p PIVOT( sum(id)FOR id in (["HI"])) s;
GO
DROP TABLE t488;
GO


-- CREATE DATBASE COLLATE (448)
CREATE DATABASE t448 COLLATE NOT_VALID_COLLATION;
GO


-- unsupported index option in CREATE INDEX (1070)
CREATE TABLE t1070(c1 int, c2 int);
GO
CREATE INDEX i1070 on t1070 (c1,c2) with allow_dup_row;
GO
DROP TABLE t1070
GO

-- XML (8113)
CREATE TABLE t8113_x(a XML);
GO
CREATE TABLE t8113_a(a int);
GO
UPDATE t8113_a SET a.query('.');
GO
DROP TABLE t8113_x;
GO
DROP TABLE t8113_a;
GO

-- NEXT VALUE FORa (11738)
CREATE SEQUENCE s11738 AS INT START WITH 5 INCREMENT BY 1;
GO
PRINT RIGHT('000000' + CAST(NEXT VALUE FOR s11738 AS NVARCHAR), 6);
GO
DROP SEQUENCE s11738;
GO

-- APPLY (4101)
CREATE TABLE t4101(c1 VARCHAR(60), c2 INT)
GO
CREATE FUNCTION f4101(@n1 INT, @n2 INT) RETURNS TABLE AS RETURN (SELECT 1 AS ret);
GO
SELECT t.c1, tmp.t2 FROM t4101 t CROSS APPLY (SELECT SUM(c2) AS t2)tmp
GO
DROP FUNCTION f4101;
GO
DROP TABLE t4101;
GO

-- XMLNAMESPACES (6869, 6870, 6871)
WITH XMLNAMESPACES ('test.com' AS ns1, 'test2.com' AS ns1) SELECT 'test' AS 'TestAttr' FOR XML RAW
GO
WITH XMLNAMESPACES ('test.com' AS n@s1) SELECT 'test' AS 'TestAttr' FOR XML RAW
GO
WITH XMLNAMESPACES ('test.com' AS xmlns) SELECT 'test' AS 'TestAttr' FOR XML RAW
GO

-- BEGIN ATOMIC (10782)
create proc p10782 AS begin atomic with (transaction isolation level = snapshot, language = N'us_english') SELECT 1; end
GO

-- DBCC (12608)
CREATE DATABASE d12608;
GO
DBCC CLONEDATABASE (d12608, d12608_clone);
GO
DROP DATABASE d12608;
GO

-- ALTER WORKLOAD GROUP (10915)
ALTER WORKLOAD GROUP internal WITH (REQUEST_MAX_MEMORY_GRANT_PERCENT = 45);
GO

-- $IDENTITY and $ROWGUID
SELECT $IDENTITY;
GO

SELECT $ROWGUID;
GO

-- TIMESTAMP and ROWVERSION
CREATE TABLE t_ts(a timestamp);
GO
CREATE TABLE t_ts2(a pg_catalog.timestamp); -- it's fine
GO
DROP TABLE t_ts2;
GO
CREATE TABLE t_rv(a ROWVERSION);
GO
CREATE PROCEDURE p_t2 (@v timestamp) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO

-- CREATE TYPE WITH (10788)
CREATE TYPE type10788 AS TABLE (c1 INT) WITH (DATA_COMPRESSION = NONE)
GO

-- ALTER TABLE ALTER COLUMN
CREATE TABLE t5074(a SMALLINT NOT NULL IDENTITY)
GO
ALTER TABLE t5074 ADD CONSTRAINT PK_t5074 PRIMARY KEY (a)
GO
ALTER TABLE t5074 ALTER COLUMN a INT NOT NULL
GO
DROP TABLE t5074
GO

-- XMLDATA
SELECT 'abc' AS 'TestAttr' FOR XML RAW, XMLDATA, ROOT;
GO

-- EXECUTE AS (487)
CREATE TABLE t487(c1 int)
GO
CREATE FUNCTION f487() RETURNS TABLE WITH EXECUTE AS 'user' AS
RETURN (SELECT * FROM t487)
GO
DROP TABLE t487
GO

-- DEFAULT arguemnt
select func1(DEFAULT);
GO

EXEC proc1 DEFAULT;
GO

-- NATIONAL/VARYING (BABEL-2360/2361)
declare @v char varying(10);
GO
declare @v char varying;
GO
declare @v character varying(10);
GO
declare @v character varying;
GO
declare @v nchar varying(10);
GO
declare @v nchar varying;
GO
declare @v national char varying(10);
GO
declare @v national char varying;
GO
declare @v national char(10);
GO
declare @v national char;
GO

-- unsupported system procedures
sp_help 'a'
GO

EXEC sp_help 'a'
GO

CREATE TABLE t_unsupported_sp (a int);
GO
INSERT INTO t_unsupported_sp EXEC sp_help 'a'
GO
DROP TABLE t_unsupported_sp;
GO
