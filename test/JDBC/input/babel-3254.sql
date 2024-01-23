-- int, bigint, smallint, tinyint, bit
create procedure babel_3254_p1 @a int,
                           @b bigint,
                           @c smallint,
                           @d tinyint,
                           @e bit,
                           @f float,
                           @g real
as select 1
go


-- char, varchar, text, nchar, nvarchar, ntext
create procedure babel_3254_p2 @a char(5),
                           @b nchar(5),
                           @c varchar(5),
                           @d nvarchar(5),
                           @e text,
                           @g ntext,
                           @h varchar(max),
                           @i nvarchar(max),
                           @j char,
                           @k varchar,
                           @l nchar,
                           @m nvarchar
as select 1
go

-- binary, varbinary, image
create procedure babel_3254_p3 @a binary,
                            @b varbinary,
                            @c binary(5),
                            @d varbinary(5),
                            @e image,
                            @f varbinary(max)
as select 1
go

-- decimal and numeric
create procedure babel_3254_p4 @a decimal,
                            @b numeric,
                            @c decimal(5,2),
                            @d numeric(5,2)
as select 1
go

-- date, datetimeoffset, datetime, datetime2, smalldatetime, time
create procedure babel_3254_p5 @a date,
                            @b datetimeoffset,
                            @c datetime,
                            @d datetime2,
                            @e smalldatetime,
                            @f time,
                            @g datetime2(7),
                            @h datetimeoffset(7),
                            @i time(7)
as select 1
go

-- money and smallmoney
create procedure babel_3254_p6 @a money,
                            @b smallmoney
as select 1
go

sp_procedure_params_100_managed 'babel_3254_p1'
go

sp_procedure_params_100_managed 'babel_3254_p2'
go

sp_procedure_params_100_managed 'babel_3254_p3'
go

sp_procedure_params_100_managed 'babel_3254_p4'
go

sp_procedure_params_100_managed 'babel_3254_p5'
go

sp_procedure_params_100_managed 'babel_3254_p6'
go

drop procedure babel_3254_p1
go

drop procedure babel_3254_p2
go

drop procedure babel_3254_p3
go

drop procedure babel_3254_p4
go

drop procedure babel_3254_p5
go

drop procedure babel_3254_p6
go
