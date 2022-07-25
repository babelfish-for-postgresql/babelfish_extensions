-- recursive procedure
-- should fail with stack depth reached error
CREATE PROC babel_1963_vu_prepare_p1 AS
BEGIN
    exec babel_1963_vu_prepare_p1
END
GO


-- recursive trigger
-- should fail with stack depth reached error
CREATE TABLE babel_1963_vu_prepare_t2 (a int)
GO

CREATE TRIGGER babel_1963_vu_prepare_trig 
ON babel_1963_vu_prepare_t2 
AFTER INSERT   
AS insert into babel_1963_vu_prepare_t2 values (1)
GO
