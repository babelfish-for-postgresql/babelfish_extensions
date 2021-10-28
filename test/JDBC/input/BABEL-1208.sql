create table babel_1208_t1 (a uniqueidentifier);
GO
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x00));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x1));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x01));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x123));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x00010203040506070809));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x000102030405060708090a0b0c0d0e0f));
insert into babel_1208_t1 values (convert(uniqueidentifier, 0x000102030405060708090a0b0c0d0e0f1011121314));
GO
select * from babel_1208_t1 order by a;
GO

-- customer scenario
CREATE TABLE babel_1208_t2([SourceActivityTypeId] [uniqueidentifier] NOT NULL)
go
ALTER TABLE babel_1208_t2 ADD DEFAULT (CONVERT([uniqueidentifier],0x00)) FOR [SourceActivityTypeId]
GO
INSERT INTO babel_1208_t2 values (default), (default);
GO
SELECT * FROM babel_1208_t2 order by 1;
GO

-- implicit castings
CREATE FUNCTION babel_1208_f_binary(@v binary(16)) RETURNS binary(16) AS BEGIN RETURN @v; END
GO
--SELECT babel_1208_f_binary(a) FROM babel_1208_t1;
GO

CREATE FUNCTION babel_1208_f_varbinary(@v varbinary(16)) RETURNS varbinary(16) AS BEGIN RETURN @v; END
GO
SELECT babel_1208_f_varbinary(a) FROM babel_1208_t1;
GO


create table babel_1208_t3 (c1 binary(16), c2 varbinary(16));
GO
insert into babel_1208_t3 values (0x000102030405060708090a0b0c0d0e0f, 0x000102030405060708090a0b0c0d0e0f);
GO

CREATE FUNCTION babel_1208_f_uuid(@u uniqueidentifier) RETURNS uniqueidentifier AS BEGIN RETURN @u; END
GO

SELECT babel_1208_f_uuid(c1) binary_in, babel_1208_f_uuid(c2) varbinary_in from babel_1208_t3
GO

-- cleanup
drop table babel_1208_t1;
GO
drop table babel_1208_t2;
GO
drop table babel_1208_t3;
GO
drop function babel_1208_f_binary;
GO
drop function babel_1208_f_varbinary;
GO
drop function babel_1208_f_uuid;
GO
