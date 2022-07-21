CREATE TABLE babel_2208_t1(c1 int, c2 varchar(10) )
GO
-- Doesn't matter if it's DECLARE or a SELECT @@rowcount
CREATE TRIGGER babel_2208_tr1 ON babel_2208_t1
AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

INSERT INTO babel_2208_t1 VALUES
    (1, 'string1' ),(2, 'string2' ),(3, 'string3' ),(4, 'string4' )
go


CREATE TABLE babel_2208_t2(c1 int, c2 varchar(10) )
go

CREATE TRIGGER babel_2208_tr2 ON babel_2208_t2
AFTER insert AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

