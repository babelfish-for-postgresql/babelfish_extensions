USE master;
go

create procedure sp1 (@a int = 0, @b varchar(10)) as begin select @a, @b; end;
go

-- Test out of order arguments
exec sp1 @b = "abcd", @a = 3;
go

-- Test normal order arguments
exec sp1 @a = 3, @b = "abcd";
go

-- Test missing argument
exec sp1 @b = "abcd";
go

-- Test truncation on varchar/varchar(1) with out of order arguments
create procedure sp2 (@a int, @b varchar) as begin select @a, @b; end;
go

-- Test out of order arguments
exec sp2 @b = "abcd", @a = 3;
go

-- Test normal order arguments
exec sp2 @a = 3, @b = "abcd";
go

-- Test OUTPUT param and missing param
create proc sp3 (@a int, @b varchar(10) = NULL, @c varchar(8) OUTPUT) as begin select @a, @b, @c; end
go

-- Test missing param @b
exec sp3 @c = 'abcdefghijklmn', @a = 1;
go

-- Test out of order arguments
exec sp3 @b = 'abcdefghijklmn', @c = 'abcdefghijklmn', @a = 1;
go

-- Test normal order arguments
exec sp3 @a = 1, @b = 'abcdefghijklmn', @c = 'abcdefghijklmn';
go

-- Clean up
drop procedure sp1, sp2, sp3;
go
