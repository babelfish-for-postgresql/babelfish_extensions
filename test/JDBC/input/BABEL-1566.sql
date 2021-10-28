-- Test CHECKSUM function works on string input
select CHECKSUM('abcd');
go

-- Test CHECKSUM function works on scalar input
select CHECKSUM(123);
go

select CHECKSUM(10.12345);
go

-- Test CHECKSUM works on table column
create table t1 (a int, b varchar(10));
insert into t1 values (12345, 'abcd');
insert into t1 values (12345, 'abcd');
insert into t1 values (23456, 'bcd');
go

select CHECKSUM(a), CHECKSUM(b) from t1;
go

-- clean up
drop table t1;
go
