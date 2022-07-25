use master
go

CREATE TABLE tt_test_t1 (col int);
INSERT INTO tt_test_t1 values (1);
INSERT INTO tt_test_t1 values (NULL);
GO

-- Implicitly creating temp tables in procedure
CREATE PROCEDURE temp_table_sp AS
BEGIN
    SELECT * INTO #tt_sp_local FROM tt_test_t1;
    INSERT INTO #tt_sp_local VALUES(2);
END;
GO

-- Drop temp table in procedure
CREATE PROCEDURE temp_table_sp_drop AS
BEGIN
    create table #t (a int);
    create table #tt (a int);
    drop table #t;
    drop table #tt;
END
go

--procedure with exeception
CREATE procedure temp_table_sp_exception AS
BEGIN
	  CREATE TABLE #tt (a int);
	  CREATE TABLE #tt (a int); -- throws error
END;
GO