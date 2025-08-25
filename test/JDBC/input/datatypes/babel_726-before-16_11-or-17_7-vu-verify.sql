-- only NULLs
select coalesce(NULL, NULL)
go

select coalesce(NULL)
go

-- Empty or white spaced strings
select coalesce('  ', 1)
go

select coalesce(2, '   ')
go

-- tab space
select coalesce(NULL, CHAR(9))
go

-- line break
select coalesce(NULL, char(13) + char(10))
go

-- constant string literal
SELECT COALESCE(NULL, 1, 2, 'I am a string')
go

SELECT COALESCE(NULL, 'I am a string', 1, 2)
go

-- precedence correctness
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- sql_variant and datetimeoffset
select coalesce(a1, a2) from babel_726_t1
GO
select coalesce(a2, a1) from babel_726_t1
GO

-- datetimeoffset and datetime2
select coalesce(a2, a3) from babel_726_t1
GO
select coalesce(a3, a2) from babel_726_t1
GO

-- datetime2 and datetime
select coalesce(a3, a4) from babel_726_t1
GO
select coalesce(a4, a3) from babel_726_t1
GO

-- datetime and smalldatetime
select coalesce(a4, a5) from babel_726_t1
GO
select coalesce(a5, a4) from babel_726_t1
GO

-- smalldatetime and date
select coalesce(a5, a6) from babel_726_t1
GO
select coalesce(a6, a5) from babel_726_t1
GO

-- date and time. Throws error as CASTing from time to DATE is not supported
select coalesce(a6, a7) from babel_726_t1
GO
select coalesce(a7, a6) from babel_726_t1
GO

-- time and float. Throws error as CASTing from float to time is not supported
select coalesce(a7, a8) from babel_726_t1
GO
select coalesce(a8, a7) from babel_726_t1
GO

-- float and real
select coalesce(a8, a9) from babel_726_t1
GO
select coalesce(a9, a8) from babel_726_t1
GO

-- real and decimal
select coalesce(a9, a10) from babel_726_t1
GO
select coalesce(a10, a9) from babel_726_t1
GO

-- decimal and money
select coalesce(a10, a11) from babel_726_t1
GO
select coalesce(a11, a10) from babel_726_t1
GO

-- money and smallmoney
select coalesce(a11, a12) from babel_726_t1
GO
select coalesce(a12, a11) from babel_726_t1
GO

-- smallmoney and bigint
select coalesce(a12, a13) from babel_726_t1
GO
select coalesce(a13, a12) from babel_726_t1
GO

-- bigint and int
select coalesce(a13, a14) from babel_726_t1
GO
select coalesce(a14, a13) from babel_726_t1
GO

-- int and smallint
select coalesce(a14, a15) from babel_726_t1
GO
select coalesce(a15, a14) from babel_726_t1
GO

-- smallint and tinyint
select coalesce(a15, a16) from babel_726_t1
GO
select coalesce(a16, a15) from babel_726_t1
GO

-- tinyint and bit
select coalesce(a16, a17) from babel_726_t1
GO
select coalesce(a17, a16) from babel_726_t1
GO

-- bit and ntext. Throws error as CASTing from ntext to bit is not supported
select coalesce(a17, a18) from babel_726_t1
GO
select coalesce(a18, a17) from babel_726_t1
GO

-- ntext and text
select coalesce(a18, a19) from babel_726_t1
GO
select coalesce(a19, a18) from babel_726_t1
GO

-- text and image.
select coalesce(a19, a20) from babel_726_t1
GO
select coalesce(a20, a19) from babel_726_t1
GO

-- image and uniqueidentifier. 
select coalesce(a20, a21) from babel_726_t1
GO
select coalesce(a21, a20) from babel_726_t1
GO

-- uniqueidentifier and nvarchar
select coalesce(a21, a22) from babel_726_t1
GO
select coalesce(a22, a21) from babel_726_t1
GO

-- nvarchar and nchar
select coalesce(a22, a23) from babel_726_t1
GO
select coalesce(a23, a22) from babel_726_t1
GO

-- nchar and varchar
select coalesce(a23, a24) from babel_726_t1
GO
select coalesce(a24, a23) from babel_726_t1
GO

-- varchar and char
select coalesce(a24, a25) from babel_726_t1
GO
select coalesce(a25, a24) from babel_726_t1
GO

-- char and varbinary
select coalesce(a25, a26) from babel_726_t1
GO
select coalesce(a26, a25) from babel_726_t1
GO

-- varbinary and binary
select coalesce(a26, a27) from babel_726_t1
GO
select coalesce(a27, a26) from babel_726_t1
GO

-- numeric and varchar
select coalesce(a28, a24) from babel_726_t1
GO
select coalesce(a24, a28) from babel_726_t1
GO

-- numeric and float
select coalesce(a28, a8) from babel_726_t1
GO
select coalesce(a8, a28) from babel_726_t1
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

select coalesce(a,b,c) from babel_726_t2
go

insert into babel_726_t2 values (NULL, 'abcde', 1.02)
go

select coalesce(a,b,c) from babel_726_t2
go

DECLARE @ID_UNDE INT = 7;
select COALESCE(@ID_UNDE, 'Não Informado')
go

exec babel_726_vu_prepare_p1
go

select babel_726_vu_prepare_f1()
go

select coalesce(CAST('x'AS VARBINARY), CAST('x' AS NVARCHAR(4000)), 'x')
go

select * from babel_726_vu_prepare_v1
go

select * from babel_726_vu_prepare_v2
go
exec babel_726_vu_prepare_p2
go

select * from babel_726_vu_prepare_v3
go
exec babel_726_vu_prepare_p3
go

select * from babel_726_vu_prepare_v4
go
exec babel_726_vu_prepare_p4
go

select * from babel_726_vu_prepare_v5
go
exec babel_726_vu_prepare_p5
go

select * from babel_726_vu_prepare_v6
go
exec babel_726_vu_prepare_p6
go

select * from babel_726_vu_prepare_v7
go
exec babel_726_vu_prepare_p7
go
