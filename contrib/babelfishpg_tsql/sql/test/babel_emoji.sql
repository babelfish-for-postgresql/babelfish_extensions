CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql" CASCADE;

-- Test SYS.NCHAR, SYS.NVARCHAR and SYS.VARCHAR
-- nchar is already available in postgres dialect
select CAST('£' AS nchar(1));
-- nvarchar is not available in postgres dialect
select CAST('£' AS nvarchar);

-- both are available in tsql dialect
set babelfishpg_tsql.sql_dialect = 'tsql';
select CAST('£' AS nchar(2));
select CAST('£' AS nvarchar(2));

-- multi-byte character doesn't fit in nchar(1) in tsql if it
-- would require a UTF16-surrogate-pair on output
select CAST('£' AS char(1));			-- allowed
select CAST('£' AS sys.nchar(1));		-- allowed
select CAST('£' AS sys.nvarchar(1));	-- allowed
select CAST('£' AS sys.varchar(1));		-- allowed

select CAST('😀' AS char(1));			-- not allowed  TODO: fix BABEL-3543
select CAST('😀' AS sys.nchar(1));		-- not allowed
select CAST('😀' AS sys.nvarchar(1));	-- not allowed
select CAST('😀' AS sys.varchar(1));	-- not allowed  TODO: fix BABEL-3543 

-- Check that things work the same in postgres dialect
reset babelfishpg_tsql.sql_dialect;
select CAST('£' AS char(1));
select CAST('£' AS sys.nchar(1));
select CAST('£' AS sys.nvarchar(1));
select CAST('£' AS sys.varchar(1));
select CAST('😀' AS char(1));
select CAST('😀' AS sys.nchar(1)); -- this should not be allowed as nchar is T-SQL type
select CAST('😀' AS sys.nvarchar(1)); -- this should not be allowed as nvarchar is T-SQL type
select CAST('😀' AS sys.varchar(1)); -- this should not be allowed as sys.varchar is T-SQL type  TODO: fix BABEL-3543 
set babelfishpg_tsql.sql_dialect = 'tsql';

-- test normal create domain works when apg_enable_domain_typmod is enabled
set apg_enable_domain_typmod true;
create domain varchar3 as varchar(3);
select CAST('ab£' AS varchar3);
select CAST('ab😀' AS varchar3); --not allowed  TODO: fix BABEL-3543 

-- don't allow surrogate pairs to exceed max length
select CAST('😀b' AS char(1));  -- not allowed TODO: fix BABEL-3543 
select CAST('😀b' AS nchar(1));
select CAST('😀b' AS nvarchar(1));
select CAST('😀b' AS sys.varchar(1)); -- not allowed TODO: fix BABEL-3543 

-- default length of nchar/char is 1 in tsql (and pg)
create table testing1(col nchar);
\d testing1;

-- check length at insert
insert into testing1 (col) select '😀';  -- not allowed TODO: fix BABEL-3543 
select * from testing1;

-- default length of nvarchar in tsql is 1
create table testing2(col nvarchar);
insert into testing2 (col) select '😀'; -- not allowed TODO: fix BABEL-3543 
select * from testing2;

-- default length of varchar in tsql is 1
create table testing4(col sys.varchar);
insert into testing4 (col) select '😀'; -- not allowed TODO: fix BABEL-3543 
-- space is automatically truncated
insert into testing2 (col) select '£ ';
insert into testing2 (col) select '🤓 '; -- not allowed TODO: fix BABEL-3543 
select * from testing4;


drop table testing1;
drop table testing2;
drop table testing3;
drop table testing4;
reset babelfishpg_tsql.sql_dialect;