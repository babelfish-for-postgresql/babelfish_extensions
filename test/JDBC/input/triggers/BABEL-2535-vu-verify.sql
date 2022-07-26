INSERT INTO babel_2535_vu_prepare_tab VALUES (1);
GO

SELECT * FROM babel_2535_vu_prepare_tmp;
GO

INSERT INTO babel_2535_vu_prepare_tab_1 VALUES (1);
INSERT INTO babel_2535_vu_prepare_tab VALUES (1);
GO

SELECT * FROM babel_2535_vu_prepare_tmp_1;
GO

SELECT * FROM babel_2535_vu_prepare_tmp;
GO

SELECT * FROM babel_2535_vu_prepare_tab_1;
GO

TRUNCATE TABLE babel_2535_vu_prepare_tmp_1;
GO

BEGIN TRAN;
GO

INSERT INTO babel_2535_vu_prepare_tab_1 VALUES (1);
INSERT INTO babel_2535_vu_prepare_tab VALUES (1);
GO

SELECT * FROM babel_2535_vu_prepare_tmp_1;
GO

SELECT * FROM babel_2535_vu_prepare_tmp;
GO

SELECT @@trancount;
GO

SELECT * FROM babel_2535_vu_prepare_tab_1;
GO

TRUNCATE TABLE babel_2535_vu_prepare_tmp;
GO

DROP TRIGGER babel_2535_vu_prepare_trg1;
GO

CREATE TRIGGER babel_2535_vu_prepare_trg1 ON babel_2535_vu_prepare_tab
AFTER INSERT AS
    SELECT 1/0;
GO

INSERT INTO babel_2535_vu_prepare_tmp VALUES (666);
INSERT INTO babel_2535_vu_prepare_tab VALUES (1);
INSERT INTO babel_2535_vu_prepare_tmp VALUES (777);
GO

SELECT * FROM babel_2535_vu_prepare_tmp;
GO

DROP TRIGGER babel_2535_vu_prepare_trg1;
GO

DROP TRIGGER babel_2535_vu_prepare_trg2;
GO

CREATE TABLE babel_2535_vu_prepare_t1 (a INT);
GO

CREATE TABLE babel_2535_vu_prepare_t2 (a INT);
GO

create trigger babel_2535_vu_prepare_trg2 on babel_2535_vu_prepare_t2 
after insert as 
begin try 
	insert into babel_2535_vu_prepare_t1 values(1); 
end try 
begin catch 
	print 'babel_2535_vu_prepare_trg2'; 
	select @@trancount; 
end catch;
GO

create trigger babel_2535_vu_prepare_trg1 on babel_2535_vu_prepare_t1 
after insert as 
begin try 
	select 1/0; 
end try 
begin catch 
	print 'babel_2535_vu_prepare_trg1'; 
	select @@trancount; 
	rollback tran; 
end catch
GO

INSERT INTO babel_2535_vu_prepare_t2 VALUES (1);
GO

DROP TRIGGER babel_2535_vu_prepare_trg1;
GO

CREATE TRIGGER babel_2535_vu_prepare_trg1 ON babel_2535_vu_prepare_t1
AFTER INSERT AS
    BEGIN TRY
        SELECT 1/0
    END TRY
    BEGIN CATCH
        SELECT XACT_STATE() AS "XACT_STATE" --Should be -1
        COMMIT
    END CATCH
go
INSERT INTO babel_2535_vu_prepare_t1 VALUES(1)
go
SELECT @@TRANCOUNT AS "TRANCOUNT" --Should be 0
go

DROP TRIGGER babel_2535_vu_prepare_trg1;
GO

CREATE TRIGGER babel_2535_vu_prepare_trg1 ON babel_2535_vu_prepare_t1
AFTER INSERT AS
    BEGIN TRY
        SELECT 1/0
    END TRY
    BEGIN CATCH
        SELECT XACT_STATE() AS "XACT_STATE" --Should be -1
        ROLLBACK
    END CATCH
go
INSERT INTO babel_2535_vu_prepare_t1 VALUES(1)
go
SELECT @@TRANCOUNT AS "TRANCOUNT" --Should be 0
go