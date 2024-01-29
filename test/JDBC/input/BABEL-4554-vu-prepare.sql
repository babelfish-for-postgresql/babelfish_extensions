-- Verify that newly created temp tables have toasts in ENR. 

CREATE TABLE #babel_4554_temp_table(a varchar(4000), b nvarchar(MAX), c sysname)
GO

-- 3: table, toast, index on toast
SELECT COUNT(*) FROM sys.babelfish_get_enr_list()
GO

DROP TABLE #babel_4554_temp_table
GO

-- 4: table, toast, index on toast, pkey
CREATE TABLE #babel_4554_temp_table_2(a sysname primary key, b nvarchar(MAX))
GO

SELECT COUNT(*) FROM sys.babelfish_get_enr_list()
GO

-- 1: index
CREATE INDEX #babel_4554_idx1 ON #babel_4554_temp_table_2(b)
GO

SELECT COUNT(*) FROM sys.babelfish_get_enr_list()
GO

DROP INDEX #babel_4554_idx1 ON #babel_4554_temp_table_2
GO

DROP TABLE #babel_4554_temp_table_2
GO

-- Verify that non-ENR tables don't put their toasts in ENR.
CREATE TYPE babel_4554_type FROM INT
GO

CREATE TABLE #babel_4554_temp_table_not_enr(a babel_4554_type, b nvarchar(MAX))
GO

SELECT COUNT(*) FROM sys.babelfish_get_enr_list()
GO

DROP TABLE #babel_4554_temp_table_not_enr
GO
