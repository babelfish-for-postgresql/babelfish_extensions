-- Dependant Functions
SELECT avg_dep_vu_prepare_f1()
GO

SELECT avg_dep_vu_prepare_f2()
GO

SELECT avg_dep_vu_prepare_f3()
GO

SELECT avg_dep_vu_prepare_f4()
GO

-- Dependant Procedures
EXEC avg_dep_vu_prepare_p1
GO

-- Dependant Views
SELECT * FROM avg_dep_vu_prepare_v1
GO

-- CLEANUP
DROP FUNCTION avg_dep_vu_prepare_f1
DROP FUNCTION avg_dep_vu_prepare_f2
DROP FUNCTION avg_dep_vu_prepare_f3
DROP FUNCTION avg_dep_vu_prepare_f4
GO

DROP PROCEDURE avg_dep_vu_prepare_p1
GO

DROP VIEW avg_dep_vu_prepare_v1
GO

DROP TABLE avg_dep_vu_prepare_t1
GO