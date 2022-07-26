create schema babel_2257_vu_prepare_error_mapping;
GO

CREATE TABLE babel_2257_vu_prepare_t1(id int);
GO

CREATE TABLE babel_2257_vu_prepare_t2(id int);
GO

CREATE TRIGGER babel_2257_vu_prepare_trig1
ON              babel_2257_vu_prepare_t1
AFTER           INSERT  
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN
        INSERT INTO babel_2257_vu_prepare_t1 VALUES (2)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE();
    END CATCH
END
GO


CREATE TRIGGER babel_2257_vu_prepare_trig2
ON              babel_2257_vu_prepare_t2
AFTER           INSERT  
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN
        INSERT INTO babel_2257_vu_prepare_t1 VALUES (1)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE();
    END CATCH
END
GO

create procedure babel_2257_vu_prepare_error_mapping.ErrorHandling1 as
begin
INSERT INTO babel_2257_vu_prepare_t2 values (1)
if @@error > 0 select cast('STATEMENT TERMINATING ERROR' as text);
end
GO


