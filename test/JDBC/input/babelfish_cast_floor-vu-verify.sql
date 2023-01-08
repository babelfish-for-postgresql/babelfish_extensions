select * from babelfish_cast_floor_bigint_v
GO

select * from babelfish_cast_floor_int_v
GO

select * from babelfish_cast_floor_smallint_v
GO

select * from babelfish_cast_floor_bigint_f();
GO

select * from babelfish_cast_floor_int_f();
GO

select * from babelfish_cast_floor_smallint_f();
GO

DROP VIEW babelfish_cast_floor_bigint_v;
GO

DROP VIEW babelfish_cast_floor_int_v;
GO

DROP VIEW babelfish_cast_floor_smallint_v;
GO

DROP FUNCTION babelfish_cast_floor_bigint_f()
GO

DROP FUNCTION babelfish_cast_floor_int_f()
GO

DROP FUNCTION babelfish_cast_floor_smallint_f()
GO