-- Fix me: will be fixed with BABEL-5155
-- -- CASE 1: T_Const LIKE T_CollateExpr(T_Const)
-- CREATE TABLE BABEL_5608_vu_prepare_t1(BABEL_5608_vu_prepare_t1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t1_c1 CHECK ('abc' LIKE 'A%' COLLATE Latin1_general_ci_as));
-- GO

-- SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t1');
-- GO

-- -- CASE 2: T_CollateExpr(T_Const) LIKE T_Const
-- CREATE TABLE BABEL_5608_vu_prepare_t2(BABEL_5608_vu_prepare_t2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t2_c1 CHECK ('abc' COLLATE Latin1_general_ci_as LIKE 'A%'));
-- GO

-- SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t2');
-- GO

-- -- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
-- CREATE TABLE BABEL_5608_vu_prepare_t3(BABEL_5608_vu_prepare_t3_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t3_c1 CHECK ('abc' COLLATE Latin1_general_ci_as LIKE 'A%' COLLATE Latin1_general_ci_as));
-- GO

-- SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t3');
-- GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
CREATE TABLE BABEL_5608_vu_prepare_t4_1(BABEL_5608_vu_prepare_t4_1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t4_1_c1 CHECK (BABEL_5608_vu_prepare_t4_1_col1 LIKE 'ABC'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t4_1');
GO

CREATE TABLE BABEL_5608_vu_prepare_t4_2(BABEL_5608_vu_prepare_t4_2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t4_2_c1 CHECK (BABEL_5608_vu_prepare_t4_2_col1 LIKE 'a%'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t4_2');
GO

-- CASE 5: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
CREATE TABLE BABEL_5608_vu_prepare_t5_1(BABEL_5608_vu_prepare_t5_1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t5_1_c1 CHECK (BABEL_5608_vu_prepare_t5_1_col1 LIKE 'ABC' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t5_1');
GO

CREATE TABLE BABEL_5608_vu_prepare_t5_2(BABEL_5608_vu_prepare_t5_2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t5_2_c1 CHECK (BABEL_5608_vu_prepare_t5_2_col1 LIKE 'a%' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t5_2');
GO

-- CASE 6: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
CREATE TABLE BABEL_5608_vu_prepare_t6(BABEL_5608_vu_prepare_t6_col1 varchar(max), BABEL_5608_vu_prepare_t6_col2 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t6_c1 CHECK (BABEL_5608_vu_prepare_t6_col1 LIKE BABEL_5608_vu_prepare_t6_col2));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t6');
GO

-- CASE 7: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
CREATE TABLE BABEL_5608_vu_prepare_t7_1(BABEL_5608_vu_prepare_t7_1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t7_1_c1 CHECK (BABEL_5608_vu_prepare_t7_1_col1 COLLATE Latin1_General_CI_AI LIKE 'abc'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t7_1');
GO

CREATE TABLE BABEL_5608_vu_prepare_t7_2(BABEL_5608_vu_prepare_t7_2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t7_2_c1 CHECK (BABEL_5608_vu_prepare_t7_2_col1 COLLATE Latin1_General_CI_AI LIKE 'a%'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t7_2');
GO

-- CASE 8: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
CREATE TABLE BABEL_5608_vu_prepare_t8_1(BABEL_5608_vu_prepare_t8_1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t8_1_c1 CHECK (BABEL_5608_vu_prepare_t8_1_col1 COLLATE Latin1_General_CI_AI LIKE 'abc' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t8_1');
GO

CREATE TABLE BABEL_5608_vu_prepare_t8_2(BABEL_5608_vu_prepare_t8_2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t8_2_c1 CHECK (BABEL_5608_vu_prepare_t8_2_col1 COLLATE Latin1_General_CI_AI LIKE 'a%' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t8_2');
GO

-- CASE 9: T_FuncExpr LIKE T_CollateExpr(T_Const) AND COMBINTAIONS
CREATE TABLE BABEL_5608_vu_prepare_t9_1(BABEL_5608_vu_prepare_t9_1_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_1_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_1_col1) LIKE 'abc'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_1');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_2(BABEL_5608_vu_prepare_t9_2_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_2_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_2_col1) LIKE 'a%'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_2');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_3(BABEL_5608_vu_prepare_t9_3_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_3_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_3_col1 COLLATE Latin1_General_CI_AI) LIKE 'abc'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_3');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_4(BABEL_5608_vu_prepare_t9_4_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_4_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_4_col1 COLLATE Latin1_General_CI_AI) LIKE 'a%'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_4');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_5(BABEL_5608_vu_prepare_t9_5_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_5_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_5_col1) COLLATE Latin1_General_CI_AI LIKE 'abc'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_5');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_6(BABEL_5608_vu_prepare_t9_6_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_6_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_6_col1) COLLATE Latin1_General_CI_AI LIKE 'a%'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_6');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_7(BABEL_5608_vu_prepare_t9_7_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_7_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_7_col1 COLLATE Latin1_General_CI_AI) LIKE 'abc' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_7');
GO

CREATE TABLE BABEL_5608_vu_prepare_t9_8(BABEL_5608_vu_prepare_t9_8_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t9_8_c1 CHECK (LOWER(BABEL_5608_vu_prepare_t9_8_col1) COLLATE Latin1_General_CI_AI LIKE 'a%' COLLATE Latin1_General_CI_AI));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t9_8');
GO

-- CASE 10: ESCAPE WITH LIKE
CREATE TABLE BABEL_5608_vu_prepare_t10(BABEL_5608_vu_prepare_t10_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t10_c1 CHECK (BABEL_5608_vu_prepare_t10_col1 COLLATE Latin1_General_CI_AS LIKE '15/% %' ESCAPE '/'));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t10');
GO

-- CASE 11: T_CoerceViaIO
CREATE TABLE BABEL_5608_vu_prepare_t11(BABEL_5608_vu_prepare_t11_col1 varchar(max), CONSTRAINT BABEL_5608_vu_prepare_t11_c1 CHECK (N'123' collate Latin1_General_CI_AI LIKE CAST(123 as varchar(3))));
GO

SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid=object_id('BABEL_5608_vu_prepare_t11');
GO
