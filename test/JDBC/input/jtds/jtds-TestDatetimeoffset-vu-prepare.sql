-- Testing inserting into the table
create table TestDatetimeoffset_vu_prepare_testing (df datetimeoffset);
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('23:40:29.998');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('1900-01-01 00:00+0:00');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('0001-01-01 00:00:00 +0:00');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('2020-03-15 09:00:00 +8:00');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('2020-03-15 09:00:00 +9:00');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('1800-03-15 09:00:00 +12:00');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('2020-03-15 09:00:00 -8:20');
go
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('1992-03-15 09:00:00');
go
-- out of range
INSERT INTO TestDatetimeoffset_vu_prepare_testing VALUES('10000-01-01 00:00:00 +0:00');
go

CREATE INDEX TestDatetimeoffset_vu_prepare_idx ON TestDatetimeoffset_vu_prepare_testing (df);
go

-- Test datetimeoffset default value
create table TestDatetimeoffset_vu_prepare_t1 (a datetimeoffset, b int);
go
insert into TestDatetimeoffset_vu_prepare_t1 (b) values (1);
go

-- test casting datetimeoffset inside procedure
-- NOTE: This is not supported behavior in tsql and will fail
CREATE PROCEDURE TestDatetimeoffset_vu_prepare_cast (@val datetimeoffset) AS
BEGIN
    DECLARE @DF datetimeoffset = @val
    PRINT @DF
    PRINT cast(@DF as datetimeoffset(5))
END;
go

-- test comparing datetimeoffset inside procedure
CREATE PROCEDURE TestDatetimeoffset_vu_prepare_cmp (@val datetimeoffset) AS
BEGIN
    IF @val > CAST('2000-01-01 13:39:29.123456 +0:00' AS datetimeoffset)
        PRINT @val - make_interval(1)
    ELSE
        PRINT @val + make_interval(1)
END;
go
