-- VOLATILE functions can not be used to generate persisted computed columns, the following
-- tests are based on this rule.

create table babel_1465_vu_prepare_t1 (id int, a varchar(10));
GO

-- CAST from char to varchar is immutable/deterministic and can be used to generate computed column
alter table babel_1465_vu_prepare_t1 add b as cast(cast('01-01-2012' as char(10)) as varchar(10)) persisted;
GO

-- CAST from sql_variant to other type is VOLATILE and is not allowed to generate computed column
alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as sql_variant) as varchar(10)) persisted;
GO

-- CAST to sql_variant from VOLATILE source type is also VOLATILE
alter table babel_1465_vu_prepare_t1 add c as cast(GETDATE() as sql_variant) persisted;
GO

-- CAST to sql_variant from datetime is VOLATILE
alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as sql_variant) persisted;
GO

-- CAST to sql_variant from smalldatetime is VOLATILE
alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as sql_variant) persisted;
GO

-- CAST from datetime/datetime2/smalldatetime to character string type/other datetime typee is VOLATILE
alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as varchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as nvarchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as char(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as nchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime) as date) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as datetime) as time) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime2) as varchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime2) as nvarchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime2) as char(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime2) as nchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as datetime2) as date) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as datetime2) as time) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as varchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as nvarchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as char(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as nchar(10)) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as smalldatetime) as date) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as smalldatetime) as time) persisted;
GO

-- CAST to datetime/datetime2/smalldatetime from character string type/datetime type is VOLATILE
alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as varchar(10)) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as char(10)) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nchar(10)) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as date) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as time) as datetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as varchar(10)) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as char(10)) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nchar(10)) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as date) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as time) as datetime2) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as varchar(10)) as smalldatetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as smalldatetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as char(10)) as smalldatetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as nchar(10)) as smalldatetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01-01-2012' as date) as smalldatetime) persisted;
GO

alter table babel_1465_vu_prepare_t1 add c as cast(cast('01:01' as time) as smalldatetime) persisted;
GO