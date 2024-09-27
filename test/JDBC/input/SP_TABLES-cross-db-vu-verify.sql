-- Case 1: Correct Database Context
USE babel_5263_vu_prepare_db1;
GO

-- Enumerate matching objects
EXEC babel_5263_vu_prepare_db1.sys.sp_tables NULL, NULL, 'babel_5263_vu_prepare_db1', NULL, 1;
GO

-- Case 2: Mismatched Database Context
USE master;
GO

-- Enumerate matching objects
EXEC babel_5263_vu_prepare_db1.sys.sp_tables NULL, NULL, 'babel_5263_vu_prepare_db1', NULL, 1;
GO

-- Case 3: No Table Qualifier - Current Database Assumed
USE babel_5263_vu_prepare_db1;
GO

EXEC babel_5263_vu_prepare_db1.sys.sp_tables NULL, NULL, NULL, NULL, 1;
GO

-- Case 4: Cross-database Access - Mismatch
USE babel_5263_vu_prepare_db1;
GO

EXEC master.sys.sp_tables NULL, NULL, 'babel_5263_vu_prepare_db1', NULL, 1;
GO

-- Case 5: Case Sensitivity in Table Qualifier
USE master;
GO

EXEC babel_5263_vu_prepare_db1.sys.sp_tables NULL, NULL, 'babel_5263_VU_prepARe_db1', NULL, 1;
GO
