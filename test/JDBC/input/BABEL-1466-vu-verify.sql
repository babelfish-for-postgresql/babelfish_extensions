-- CONVERT from int to smallint is immutable/deterministic and can be used to generate computed column
alter table babel_1466_vu_prepare_t1 add b as convert(smallint, 1) persisted;
GO

-- TODO CONVERT from int to string type is immutable and can be used to generate computed column
-- This is not straightforward to change atm because we currently use a wrapper function babelfish_conv_helper_to_varchar
-- to implement convert to varchar (in order to support the style parameter in convert),
-- and the function is defined as either VOLAITLE or IMMUTABLE (can't be IMMUTABLE conditionally)
-- However, in SQL Server convert to varchar is IMMUTABLE conditionally.
alter table babel_1466_vu_prepare_t1 add c as convert(varchar(2), 1) persisted;
GO

-- CONVERT from sql_variant to other types are volatile and can not be used to generate computed column
alter table babel_1466_vu_prepare_t1 add d as convert(smallint, convert(sql_variant, 1)) persisted;
GO

-- CONVERT from datetime/datetime2/smalldatetime to string type is volatile and can not be used to generate computed column
alter table babel_1466_vu_prepare_t1 add d as convert(varchar(15), convert(datetime, '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(char(15), convert(datetime, '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(varchar(15), convert(datetime2, '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(char(15), convert(datetime2, '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(varchar(15), convert(smalldatetime, '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(char(15), convert(smalldatetime, '01-01-2012')) persisted;
GO

-- CONVERT from datetime column to string type is volatile and can not be used to generate computed column
alter table babel_1466_vu_prepare_t1 add d as convert(varchar(15), t) persisted;
GO

-- CONVERT from string type to datetime/datetime2/smalldatetime is volatile and can not be used to generate computed column
alter table babel_1466_vu_prepare_t1 add d as convert(datetime, convert(varchar(15), '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(datetime, convert(char(15), '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(datetime2, convert(varchar(15), '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(datetime2, convert(char(15), '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(smalldatetime, convert(varchar(15), '01-01-2012')) persisted;
GO

alter table babel_1466_vu_prepare_t1 add d as convert(smalldatetime, convert(char(15), '01-01-2012')) persisted;
GO