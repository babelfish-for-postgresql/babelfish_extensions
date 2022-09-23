-- Table without table_name
CREATE TABLE (a int)
GO

-- Table without a datatype of column
CREATE TABLE BABEL_1953_vu_prepare_t1 (a)
GO
CREATE TABLE BABEL_1953_vu_prepare_t2 (a, b int)
GO
CREATE TABLE BABEL_1953_vu_prepare_t3 (a int, b)
GO

-- Table without table_name and datatype of a column
CREATE TABLE (a)
GO

-- Table having datatype mentioned before the column_name
CREATE TABLE BABEL_1953_vu_prepare_t4 (int a)
GO

-- Table without column_name but datatype
CREATE TABLE BABEL_1953_vu_prepare_t5 (int)
GO
CREATE TABLE BABEL_1953_vu_prepare_t6 (a int, varchar(5))
GO


-- Table_name starting with integers and special characters
CREATE TABLE 1953_vu_prepare_t7 (a int)
GO
CREATE TABLE @ (a int)
GO
CREATE TABLE $ (a int)
GO

-- Table having integers and special characters as the column name
CREATE TABLE BABEL_1953_vu_prepare_t8 (123a int)
GO
CREATE TABLE BABEL_1953_vu_prepare_t9 (@ int)
GO
CREATE TABLE BABEL_1953_vu_prepare_t11 ($ int)
GO

-- Table without columns
CREATE TABLE BABEL_1953_vu_prepare_t12
GO
CREATE TABLE BABEL_1953_vu_prepare_t13 ()
GO

-- Table having same column_name with same datatype and different datatype
CREATE TABLE BABEL_1953_vu_prepare_t14 (a int, a int)
GO
CREATE TABLE BABEL_1953_vu_prepare_t15 (a int, int a)
GO
CREATE TABLE BABEL_1953_vu_prepare_t16 (a int, a varchar(5))
GO

-- Test on VIEWS
CREATE TABLE BABEL_1953_vu_prepare_t17(a int)
GO
CREATE VIEW 123view AS SELECT * FROM BABEL_1953_vu_prepare_t17
GO
CREATE VIEW @ AS SELECT * FROM BABEL_1953_vu_prepare_t17
GO
CREATE VIEW $ AS SELECT * FROM BABEL_1953_vu_prepare_t17
GO