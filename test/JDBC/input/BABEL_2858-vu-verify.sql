SELECT set_config('babelfishpg_tsql.enable_sll_parse_mode', 'true', false)
GO
-- valid sll parsing and ll parsing
SELECT * FROM babel_2858_t1
GO

-- fails both sll parsing and ll parsing
SELECT FROM WHERE GROUP BY
GO

-- fails sll parsing passes ll parsing passes, valid query
delete babel_2858_t1
output babel_2858_t1.word
from babel_2858_t1
inner join babel_2858_t1_deleted
 on babel_2858_t1.num=babel_2858_t1_deleted.num
where babel_2858_t1.num=14;
go

-- fails sll parsing ll parsing passes, invalid query
DECLARE @x xml (dbo.f);
GO

SELECT set_config('babelfishpg_tsql.enable_sll_parse_mode', 'false', false)
GO