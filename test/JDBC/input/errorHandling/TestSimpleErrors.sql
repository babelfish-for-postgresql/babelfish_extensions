-- sla_for_parallel_query_enforced 100000
CREATE TABLE simpleErrorTable (a varchar(15) UNIQUE NOT NULL, b nvarchar(25), c int PRIMARY KEY, d char(15) DEFAULT 'Whoops!', e nchar(25), f datetime, g numeric(4,1) CHECK (g >= 103.5))
GO

-- setup for "data out of range for datetime" error
CREATE TABLE t517_1(a datetime);
GO

-- setup for "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations" error
CREATE TABLE t141_1(c1 int, c2 int); 
GO

-- setup for "column \"%s\" of relation \"%s\" is a generated column"
CREATE TABLE t1752_1(c1 INT, c2 INT, c3 as c1*c2)
GO

if @@trancount > 0 commit tran;
GO

-- Error: duplicate key value violates unique constraint
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    save tran sp1; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran sp1
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4); 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4); 
    commit tran; 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4); 
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: duplicate key value violates unique constraint
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    rollback tran sp1;
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
            declare @err int = @@error; if @err = 0 select 0 else select 1;
    commit tran; 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: data out of range for datetime
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        INSERT INTO t517_1 VALUES (DATEADD(YY,-300,getdate()));
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
    rollback tran sp1;
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    commit tran; 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
        declare @err int = @@error; if @err = 0 select 0 else select 1;
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: not null constraint violation
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET c = NULL WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO


-- Error: creating an existing table
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
CREATE TABLE simpleErrorTable (a int);
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
rollback tran sp1;
GO
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        CREATE TABLE simpleErrorTable (a int);
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran;
GO
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                CREATE TABLE simpleErrorTable (a int);
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE simpleErrorTable (a int);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    CREATE TABLE simpleErrorTable (a int);
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE simpleErrorTable (a int);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: creating an existing table
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        CREATE TABLE simpleErrorTable (a int);
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO


-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    save tran sp1; 
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran sp1; 
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    commit tran; 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: "column \"%s\" of relation \"%s\" is a generated column"
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        ALTER TABLE t1752_1 ADD CONSTRAINT constraint1752 DEFAULT 'test' FOR c3;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
	DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
	DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran sp1;
GO
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO


-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
DECLARE @a tinyint = 1000;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
DECLARE @a tinyint = 1000;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
commit tran
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a tinyint = 1000;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    DECLARE @a tinyint = 1000;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc3
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        DECLARE @a tinyint = 1000;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: "A SELECT statement that assigns a value to a variable must not be
-- combined with data-retrieval operations"
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DECLARE @a int; SELECT @a = c1, c2 FROM t141_1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        DECLARE @a tinyint = 1000;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

select @@trancount;
GO

if @@trancount > 0 commit tran;
GO

-- Error: value for domain tinyint violates check constraint "tinyint_check"
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
DECLARE @a tinyint = 1000;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
GO
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
GO
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
GO
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
rollback tran sp1;
GO
rollback tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
GO
commit tran; 
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
commit tran;
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
commit tran
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
create procedure simpleErrorProc2
as
begin
    INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
    exec simpleErrorProc1;
    INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
end
GO
create procedure simpleErrorProc3
as
begin
    SELECT 1;
    exec simpleErrorProc2;
    SELECT 2;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
drop procedure simpleErrorProc3
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    commit tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: conversion error and executing stored procedure using sp_executesql
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
create procedure simpleErrorProc2
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Pineapple', N'pink', 7, 'Surat', N'Frown😠',  '2000-12-13 12:58:23.123', 123.1);
        exec simpleErrorProc1;
        INSERT INTO simpleErrorTable VALUES ('Cherry', N'indigo', 8, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    rollback tran;
end
GO
exec simpleErrorProc2
GO
declare @err int = @@error; if @err = 0 select 0 else select 1;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- cleanup for "data out of range for datetime" error
DROP TABLE t517_1;
GO

-- clean up for "A SELECT statement that assigns a value to a variable must not
-- be combined with data-retrieval operations" error
DROP TABLE t141_1;
GO

-- setup for "column \"%s\" of relation \"%s\" is a generated column"
DROP TABLE t1752_1;
GO

drop table simpleErrorTable
GO

while (@@trancount > 0) commit tran;
GO

