-- Initialize Procedure
create proc [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] @in INT AS SELECT @in;
go

-- Expect error for duplicate procedure
create proc [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] @in INT AS SELECT @in;
go

-- Expect error for duplicate function
create function [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (@input int)
returns varchar(250)
as begin
    return "test"
end
go

-- Cleanup
drop proc [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
go

-- Initialize Function
create function [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (@input int)
returns varchar(250)
as begin
    return "test"
end
go

-- Expect error for duplicate function 
create function [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (@input int)
returns varchar(250)
as begin
    return "test"
end
go

-- Cleanup
drop function [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
go

-- Initialize View
create view [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] 
as
    select 1
go

-- Expect error for duplicate view
create view [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] 
as
    select 1
go

-- Expect error for duplicate relation
create table [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (
    col1 int
);
go

-- Cleanup
drop view [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
go

-- Initialize Table
create table [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (
    col1 int
);
go

-- Expect error for duplicate table
create table [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##] (
    col1 int
);
go

-- Cleanup
drop table [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
go

create table t1 (
    col1 int
);
go

-- Initialize Trigger
create trigger [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
on t1
for
insert
as
print 'Table blocked from insert'
rollback;
go

-- Expect error for duplicate trigger
create trigger [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
on t1
for
insert
as
print 'Table blocked from insert'
rollback;
go

-- Cleanup
drop trigger [%%#%@$^$姓氏すず🤬🤯🫣🤗🫡🤔🫢🤭き,😀 鈴木##]
go

drop table t1
go

-- database name with multi byte characters
CREATE DATABASE ["龙漫远; 龍漫😃😄漫遠.¢£€¥"]
GO
CREATE DATABASE ["龙漫远; 龍漫😃😄漫遠.¢£€¥"]
GO
USE ["龙漫远; 龍漫😃😄漫遠.¢£€¥"]
GO
USE master
GO
DROP DATABASE ["龙漫远; 龍漫😃😄漫遠.¢£€¥"]
GO
