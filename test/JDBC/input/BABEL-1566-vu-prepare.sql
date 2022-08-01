-- Test CHECKSUM works on table column
create table BABEL_1566_vu_prepare_1 (a int, b varchar(10));
insert into BABEL_1566_vu_prepare_1 values (12345, 'abcd');
insert into BABEL_1566_vu_prepare_1 values (12345, 'abcd');
insert into BABEL_1566_vu_prepare_1 values (23456, 'bcd');
go

-- Test checksum on table with null input and empty string
create table BABEL_1566_vu_prepare_2 (a varchar(10), b int);
go

insert into BABEL_1566_vu_prepare_2 values ('', 1);
go

insert into BABEL_1566_vu_prepare_2 values (null, 2);
go

insert into BABEL_1566_vu_prepare_2 values ('empty', 3);
go

create table BABEL_1566_vu_prepare_3(a int)
go

insert into BABEL_1566_vu_prepare_3 values(1)
go

create table BABEL_1566_vu_prepare_dates(a date, b time, c datetimeoffset, d datetime2, e datetime, f smalldatetime)
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

create table BABEL_1566_vu_prepare_4(a binary, b bit, c timestamp, d bytea, e sql_variant, f varbinary)
go