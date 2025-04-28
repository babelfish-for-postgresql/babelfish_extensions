-- dependent objects
SELECT * FROM fn_varbintohexsubstring_vu_prepare_view
GO

EXEC fn_varbintohexsubstring_vu_prepare_proc
GO

SELECT * FROM fn_varbintohexsubstring_vu_prepare_func()
GO

-- NULL expression results in NULL output
SELECT sys.fn_varbintohexsubstring(0,0x,1,3);
GO

SELECT sys.fn_varbintohexsubstring(0,CAST(NULL AS VARBINARY),1,4);
GO

-- if substr_length is NULL, negative, zero or greater than length of expression, set substr_length as length of expression
SELECT sys.fn_varbintohexsubstring(1,0x123486534659789876435656,1,NULL);
GO

SELECT sys.fn_varbintohexsubstring(1, 0x123486534659789876435656, 1, -5);
GO

SELECT sys.fn_varbintohexsubstring(1,0x123486534659789876435656,1,0);
GO

SELECT sys.fn_varbintohexsubstring(1,0x123486534659789876435656,1,100);
GO

-- if substr_length is out of bounds of the expression, then len is set to the length of expression - start_offset
SELECT sys.fn_varbintohexsubstring(1, 0x123486534659789876435656, 3, 20);
GO

-- if set_prefix is NULL or 0, no prefix is added
SELECT sys.fn_varbintohexsubstring(NULL,0x123486534659789876435656,1,4);
GO

SELECT sys.fn_varbintohexsubstring(0,0x123486534659789876435656,1,4);
GO

-- if set_prefix is 1 or any other integer except 0, prefix is added
SELECT sys.fn_varbintohexsubstring(1,0x123486534659789876435656,1,4);
GO

SELECT sys.fn_varbintohexsubstring(52,0x123486534659789876435656,1,4);
GO

SELECT sys.fn_varbintohexsubstring(-81,0x123486534659789876435656,1,4);
GO

-- if start_offset is NULL or 0 or negative, return NULL
SELECT sys.fn_varbintohexsubstring(1,0x87243478679,NULL,4);
GO

SELECT sys.fn_varbintohexsubstring(1,0x87243478679,CAST(NULL AS INT),4);
GO

SELECT sys.fn_varbintohexsubstring(1,0x87243478679,0,4);
GO

SELECT sys.fn_varbintohexsubstring(1, 0x123456, -1, 2);
GO

-- if start_offset is out of bound, return NULL
SELECT sys.fn_varbintohexsubstring(1, 0x123456, 100, 2);
GO

-- NULL edge cases
SELECT sys.fn_varbintohexsubstring(NULL,NULL,NULL,NULL);
GO

SELECT sys.fn_varbintohexsubstring(NULL,0x8675235657899765,NULL,NULL);
GO

SELECT sys.fn_varbintohexsubstring(NULL,0x8675235657899765,2,NULL);
GO

--negative test as varbinary only consists of 0-9 and A-F
SELECT sys.fn_varbintohexsubstring(1,0x1452J5S4, 2, 4);  
GO

-- negative test gives error as the expression datatype is not varbinary
SELECT sys.fn_varbintohexsubstring(1,'1A2B3C4D', 2, 4);  
GO

-- validate check constraint
INSERT INTO babel_5654_t1 VALUES (0,0x123486534659789876435656,1,4)
GO
INSERT INTO babel_5654_t1 VALUES (1,0x123486534659789876435656,1,4)
GO
INSERT INTO babel_5654_t1 VALUES (1,0x123486534659789876435656,3,4)
GO

SELECT * FROM babel_5654_t1
GO

-- computed columns
INSERT INTO babel_5654_t2 VALUES (1,0x23486534659789876435656,3,4)
GO

SELECT * FROM babel_5654_t2 WHERE [varbintohexsubstring] = sys.fn_varbintohexsubstring(1,0x23486534659789876435656,3,4)
GO

-- computed columns with user defined datatypes
INSERT INTO babel_5654_t3 VALUES (1,0x23486534659789876435656,3,4)
GO

SELECT * FROM babel_5654_t3 WHERE [varbintohexsubstring] = sys.fn_varbintohexsubstring(1,0x23486534659789876435656,3,4)
GO
 