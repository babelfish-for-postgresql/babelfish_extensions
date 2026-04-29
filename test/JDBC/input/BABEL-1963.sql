-- recursive procedure
-- should fail with stack depth reached error
SELECT set_config('babelfishpg_tsql.enable_antlr_parse_cache', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.force_antlr_cache_testing', 'off', false);
GO
CREATE PROC p1 AS
BEGIN
    exec p1
END
GO

-- tsql
SELECT set_config('babelfishpg_tsql.enable_antlr_parse_cache', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.force_antlr_cache_testing', 'off', false);
GO
exec p1
go

-- recursive trigger
-- should fail with stack depth reached error
CREATE TABLE table2_1963 (a int)
GO

CREATE TRIGGER trig2_1963 
ON table2_1963 
AFTER INSERT   
AS insert into table2_1963 values (1)
GO

insert into table2_1963 values(5)
go


-- cleanup
drop table table2_1963;
go

drop procedure p1
go