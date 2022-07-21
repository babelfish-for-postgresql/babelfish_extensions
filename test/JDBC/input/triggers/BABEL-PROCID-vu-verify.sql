-- Test outside of a procedure
SELECT @@PROCID;
GO

-- Test procedure
EXEC babel_procid_proc1;
GO

-- Test nested procedure
EXEC babel_procid_proc2;
GO

-- Test UDF function
SELECT babel_procid_func1();
GO

-- Test nested function inside a procedure
EXEC babel_procid_proc3;
GO

-- Test nested function inside a function
SELECT * FROM babel_procid_func3();
GO

-- Test triggers
INSERT INTO babel_procid_data1(a) VALUES(1);
GO

-- Should print name of the trigger
SELECT * FROM babel_procid_data_log;
GO


--Test nested function and procedure inside a trigger
INSERT INTO babel_procid_data2(a) VALUES(1);
GO


-- Test when nested module throws error
EXEC babel_procid_proc5;
GO

INSERT INTO babel_procid_data3(a) VALUES(3);
GO

-- Test insert through a procedure
EXEC babel_procid_table_insert 4;
GO

