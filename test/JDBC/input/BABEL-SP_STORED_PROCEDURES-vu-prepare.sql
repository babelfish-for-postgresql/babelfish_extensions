DROP DATABASE IF EXISTS babel_sp_stored_procedures_vu_prepare_db1
GO
CREATE DATABASE babel_sp_stored_procedures_vu_prepare_db1
GO
USE babel_sp_stored_procedures_vu_prepare_db1
GO

DROP TABLE IF EXISTS babel_sp_stored_procedures_vu_prepare_t1
GO
CREATE TABLE babel_sp_stored_procedures_vu_prepare_t1(a INT, PRIMARY KEY(a))
GO

DROP PROCEDURE IF EXISTS babel_sp_stored_procedures_vu_prepare_select_all
GO
CREATE PROCEDURE babel_sp_stored_procedures_vu_prepare_select_all
AS
SELECT * FROM babel_sp_stored_procedures_vu_prepare_t1
GO

DROP PROCEDURE IF EXISTS babel_sp_stored_procedures_vu_prepare_seluct_all
GO
CREATE PROCEDURE babel_sp_stored_procedures_vu_prepare_seluct_all
AS
SELECT * FROM babel_sp_stored_procedures_vu_prepare_t1
GO

DROP PROCEDURE IF EXISTS babel_sp_stored_procedures_vu_prepare_select_all_Mixed
GO
CREATE PROCEDURE babel_sp_stored_procedures_vu_prepare_select_all_Mixed
AS
SELECT * FROM babel_sp_stored_procedures_vu_prepare_t1
GO

CREATE SCHEMA babel_sp_stored_procedures_vu_prepare_s1
GO

DROP FUNCTION IF EXISTS babel_sp_stored_procedures_vu_prepare_s1.positive_or_negative
GO

CREATE FUNCTION babel_sp_stored_procedures_vu_prepare_s1.positive_or_negative (
	@long DECIMAL(9,6)
)
RETURNS CHAR(4) AS
BEGIN
	DECLARE @return_value CHAR(10);
	SET @return_value = 'zero';
    IF (@long > 0.00) SET @return_value = 'positive';
    IF (@long < 0.00) SET @return_value = 'negative';
 
    RETURN @return_value
END;
GO