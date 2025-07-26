-- testing UDT
SELECT CAST(678.90 AS babel_5512_upgrade_type1) + CAST(123.45 AS NUMERIC(5,2))AS result;
GO

create table babel_5512_upgrade_t5 (smallmoney_udt_col babel_5512_upgrade_type1)
GO

Insert into babel_5512_upgrade_t5 values (678.90)
GO

select smallmoney_udt_col + CAST(123.45 AS NUMERIC(5,2))AS result from babel_5512_upgrade_t5;
GO

select a16 + CAST(123.45 AS NUMERIC(5,2))AS result from babel_5512_upgrade_t2;
GO

--------------------
-- procedure/function
--------------------
-- Functions
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f1';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f2';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f3';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f4';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f5';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f6';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f7';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_f8';
GO
-- ITVF, MSTVF
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_itvf1';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_itvf2';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_mstvf1';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_mstvf2';
GO

-- Procedures
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p1';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p2';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p3';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p4';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p5';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p6';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p7';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p8';
GO
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_5512_upgrade_p9';
GO

-- To execute the procedure
EXEC babel_5512_upgrade_p10;
GO
EXEC babel_5512_upgrade_p11;
GO

-- To execute the function
SELECT babel_5512_upgrade_f9();
GO
SELECT babel_5512_upgrade_f10();
GO

-----------------------
-- table/views etc.
------------------------

-- see p&s
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t1'
GO
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t2'
GO
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t3'
GO
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t9'
GO
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t10'
GO
EXEC babel_5512_get_column_info_p10 'babel_5512_upgrade_t11'
GO
EXEC babel_5512_get_column_info_p10 '@customerswithorders_babel_5512_upgrade_mstvf1'
GO
EXEC babel_5512_get_column_info_p10 '@tablevar_babel_5512_upgrade_mstvf2'
GO

select * from babel_5512_upgrade_t1
GO

select coalesce(a10, a11) from babel_5512_upgrade_t1
GO

select coalesce(a15, a16) from babel_5512_upgrade_t2
GO

SELECT * FROM babel_5512_upgrade_v1;
GO

SELECT * FROM babel_5512_upgrade_v2;
GO

SELECT * FROM babel_5512_upgrade_v3;
GO
SELECT * FROM babel_5512_upgrade_v6;
GO
SELECT * FROM babel_5512_upgrade_v7;
GO
SELECT * FROM babel_5512_upgrade_v8;
GO
SELECT * FROM babel_5512_upgrade_v9;
GO

-- for r,i,v,p,I
SELECT c.relkind as object_type, a.attname as column_name, a.atttypid::regtype::text as data_type, a.atttypmod as type_modifier 
FROM pg_class c 
JOIN pg_attribute a ON c.oid = a.attrelid 
WHERE a.atttypid::regtype::text IN ('money', 'smallmoney') 
AND a.attname IN ('babel_5512_mon3','babel_5512_mon1','babel_5512_small3','babel_5512_result1',
            'babel_5512_result2','babel_5512_result3','babel_5512_result4','babel_5512_result5','babel_5512_result6','babel_5512_small1') 
AND c.relkind IN ('r', 'i', 'v', 'p', 'I') 
ORDER BY c.relkind, c.relname, a.attname;
GO

