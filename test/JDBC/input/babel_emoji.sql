-- Test SYS.NCHAR, SYS.NVARCHAR and SYS.VARCHAR
-- nchar is already available in postgres dialect
select CAST('£' AS nchar(1));
GO
-- nvarchar is not available in postgres dialect
select CAST('£' AS nvarchar);
GO

-- both are available in tsql dialect
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
select CAST('😀b' AS sys.varchar(1)); -- not allowed TODO: fix BABEL-3543 
GO

-- default length of nchar/char is 1 in tsql (and pg)
create table testing_1(col nchar);
GO

SELECT * FROM information_schema.columns WHERE table_name = 'testing_1'
GO

-- default length of varchar in tsql is 1
create table testing_4(col sys.varchar);
insert into testing_4 (col) select '😀'; -- not allowed TODO: fix BABEL-3543 
GO

select * from testing_4;
GO


drop table testing_1;
GO
drop table testing_4;
GO

drop type varchar3;
GO
