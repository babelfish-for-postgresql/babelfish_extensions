-- additional tests for DATALENGTH (more types, nullvalues)
CREATE table babel_function_string_vu_prepare_1 (a binary(10), b image, c varbinary(10), d char(10),
			     e varchar(10), f text, g nchar(10), h nvarchar(10), i ntext)
GO

INSERT into babel_function_string_vu_prepare_1 values (cast('abc' as binary(10)), cast('abc' as image), cast('abc' as varbinary(10)),'abc','abc','abc','abc','abc','abc')
GO

INSERT into babel_function_string_vu_prepare_1 values (null, null, null, null, null, null,null, null, null)
GO

CREATE table babel_function_string_vu_prepare_2 (a integer, b bigint, c bit, d smallint, e tinyint, f decimal, g numeric, h float, i real)
GO

INSERT into babel_function_string_vu_prepare_2 values (1, 1, 1, 1, 1, 1, 1, 1, 1)
GO

INSERT into babel_function_string_vu_prepare_2 values (null, null, null, null, null, null,null, null, null)
GO

CREATE table babel_function_string_vu_prepare_3 (a smallmoney, b money, c date, d datetime, e datetime2, f smalldatetime, g time, h uniqueidentifier)
GO

INSERT into babel_function_string_vu_prepare_3 values (cast(1 as smallmoney), cast(1 as money), cast('2020-02-20' as date), cast('2020-02-20 20:20:20.888' as datetime), 
                        cast('2020-02-20 20:20:20.88888' as datetime2), cast('2020-02-20 20:20:20' as smalldatetime), cast('20:20:20.888' as time), 
                        cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as uniqueidentifier))
GO

INSERT into babel_function_string_vu_prepare_3 values (null, null, null, null, null, null,null, null)
GO