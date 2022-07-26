CREATE TABLE babel_2535_vu_prepare_tab (a INT)
GO
CREATE TABLE babel_2535_vu_prepare_tmp (a INT)
GO

CREATE TRIGGER babel_2535_vu_prepare_trg1 ON babel_2535_vu_prepare_tab
AFTER INSERT AS
    BEGIN TRY
		INSERT INTO babel_2535_vu_prepare_tmp VALUES (1);
        SELECT 1/0;
		INSERT INTO babel_2535_vu_prepare_tmp VALUES (2);
    END TRY
    BEGIN CATCH
        SELECT XACT_STATE() AS "XACT_STATE"
    END CATCH
GO

CREATE TABLE babel_2535_vu_prepare_tab_1 (a INT)
GO

CREATE TABLE babel_2535_vu_prepare_tmp_1 (a INT)
GO

CREATE TRIGGER babel_2535_vu_prepare_trg2 ON babel_2535_vu_prepare_tab_1
AFTER INSERT AS
    INSERT INTO babel_2535_vu_prepare_tmp_1 VALUES (555);
GO
