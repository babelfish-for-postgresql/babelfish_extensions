RAISERROR('%s', 16, 1, 'Hi');
go

RAISERROR('Hello %s', 16, 1, 'World');
go

DECLARE @str VARCHAR(20) = 'Multiple variable inputs';
DECLARE @p1 TINYINT = 1;
DECLARE @p2 SMALLINT = 2;
DECLARE @p3 INT = 3;
DECLARE @p4 CHAR(5) = 'four';
DECLARE @p5 VARCHAR(5) = 'five';
DECLARE @p6 NCHAR(5) = 'six';
DECLARE @p7 NVARCHAR(5) = 'seven';
RAISERROR('%s: %d%d%d%s%s%s%s', 16, 1, @str, @p1, @p2, @p3, @p4, @p5, @p6, @p7);
go

RAISERROR('More than 20 args', 16, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);
go

RAISERROR('Signed integer i: %i, %i', 16, 1, 5, -5);
go

RAISERROR('Unsigned integer u: %u, %u', 16, 1, 5, -5);
go

RAISERROR('Unsigned octal o: %o, %o', 16, 1, 5, -5);
go

RAISERROR('Unsigned hexadecimal x: %x, %X, %X, %X, %x', 16, 1, 11, 11, -11, 50, -50);
go

RAISERROR('Not enough args: %d, %d', 16, 1, 1, 2, 3, 4);
go

RAISERROR('No arg for placeholder: %s', 16, 1);
go

RAISERROR('Invalid placeholder: %m', 16, 1, 0);
go

RAISERROR('Null arg for placeholder: %s', 16, 1, NULL);
go

-- Datatype mismatch
RAISERROR('Mismatch datatype: %d', 16, 1, 'string');
go

RAISERROR('Mismatch datatype: %o', 16, 1, N'string');
go

RAISERROR('Mismatch datatype: %s', 16, 1, 123);
go
