-- Test SYS.NCHAR, SYS.NVARCHAR and SYS.VARCHAR
-- nchar is already available in postgres dialect
select CAST('£' AS nchar(1));
GO
-- nvarchar is not available in postgres dialect
select CAST('£' AS nvarchar);
GO

-- both are available in tsql dialect
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select CAST('£' AS nchar(2));
GO
select CAST('£' AS nvarchar(2));
GO

-- multi-byte character doesn't fit in nchar(1) in tsql if it
-- would require a UTF16-surrogate-pair on output
select CAST('£' AS char(1));			-- allowed
GO
select CAST('£' AS sys.nchar(1));		-- allowed
GO
select CAST('£' AS sys.nvarchar(1));	-- allowed
GO
select CAST('£' AS sys.varchar(1));		-- allowed
GO

select CAST('😀' AS char(1));			-- not allowed  TODO: fix BABEL-3543
GO
select CAST('😀' AS sys.nchar(1));		-- not allowed
GO
select CAST('😀' AS sys.nvarchar(1));	-- not allowed
GO
select CAST('😀' AS sys.varchar(1));	-- not allowed  TODO: fix BABEL-3543 
GO

-- Check that things work the same in postgres dialect
select CAST('£' AS char(1));
GO
select CAST('£' AS sys.nchar(1));
GO
select CAST('£' AS sys.nvarchar(1));
GO
select CAST('£' AS sys.varchar(1));
GO
select CAST('😀' AS char(1));
GO
select CAST('😀' AS sys.nchar(1)); -- this should not be allowed as nchar is T-SQL type
GO
select CAST('😀' AS sys.nvarchar(1)); -- this should not be allowed as nvarchar is T-SQL type
GO
select CAST('😀' AS sys.varchar(1)); -- this should not be allowed as sys.varchar is T-SQL type  TODO: fix BABEL-3543 
GO
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- test normal create domain works when apg_enable_domain_typmod is enabled
-- set apg_enable_domain_typmod true;
create TYPE varchar3 FROM varchar(3);
select CAST('ab£' AS varchar3);
GO
select CAST('ab😀' AS varchar3); --not allowed  TODO: fix BABEL-3543 
GO

-- don't allow surrogate pairs to exceed max length
select CAST('😀b' AS char(1));  -- not allowed TODO: fix BABEL-3543 
GO
select CAST('😀b' AS nchar(1));
GO
select CAST('😀b' AS nvarchar(1));
GO
select CAST('😀b' AS sys.varchar(1)); -- not allowed TODO: fix BABEL-3543 
GO

-- default length of nchar/char is 1 in tsql (and pg)
create table testing1(col nchar);
GO

SELECT * FROM information_schema.columns WHERE table_name = 'testing1'
GO

-- check length at insert
insert into testing1 (col) select '😀';  -- not allowed TODO: fix BABEL-3543 
select * from testing1;
GO

-- default length of nvarchar in tsql is 1
create table testing2(col nvarchar);
insert into testing2 (col) select '😀'; -- not allowed TODO: fix BABEL-3543 
select * from testing2;
GO

-- default length of varchar in tsql is 1
create table testing4(col sys.varchar);
insert into testing4 (col) select '😀'; -- not allowed TODO: fix BABEL-3543 
GO
-- space is automatically truncated
insert into testing2 (col) select '£ ';
GO
insert into testing2 (col) select '🤓 '; -- not allowed TODO: fix BABEL-3543 
select * from testing4;
GO


drop table testing1;
GO
drop table testing2;
GO
drop table testing4;
GO
