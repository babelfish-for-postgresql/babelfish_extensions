SET XACT_ABORT ON
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
GO

CREATE TABLE simpleErrorTable (a varchar(15) UNIQUE, b nvarchar(25), c int PRIMARY KEY, d char(15) DEFAULT 'Whoops!', e nchar(25), f datetime, g numeric(4,1) CHECK (g >= 103.5))
GO

-- Error: duplicate key value violates unique constraint
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
INSERT INTO simpleErrorTable VALUES ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4); 
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
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran sp1
rollback tran;
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


-- Error: check constraint violation
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    rollback tran sp1;
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
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

-- Error: check constraint violation
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
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

-- Error: check constraint violation
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
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
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: check constraint violation
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
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

-- Error: check constraint violation
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
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

-- Error: check constraint violation
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE simpleErrorTable SET g = 101.4 WHERE c = 1;
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
rollback tran;
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
    rollback tran sp1;
rollback tran;
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
commit tran;
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
commit tran;
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
rollback tran;
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
    rollback tran sp1;
rollback tran;
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


-- Error: deleting values from a table that does not exist
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
DELETE FROM simpleErrorTable1 WHERE c = 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: deleting values from a table that does not exist
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
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

-- Error: deleting values from a table that does not exist
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
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

-- Error: deleting values from a table that does not exist
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    save tran sp1; 
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran sp1; 
rollback tran;
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

-- Error: deleting values from a table that does not exist
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: deleting values from a table that does not exist
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        DELETE FROM simpleErrorTable1 WHERE c = 1;
    commit tran; 
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
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

-- Error: deleting values from a table that does not exist
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                DELETE FROM simpleErrorTable1 WHERE c = 1;
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
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

-- Error: deleting values from a table that does not exist
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DELETE FROM simpleErrorTable1 WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
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

-- Error: deleting values from a table that does not exist
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
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

-- Error: deleting values from a table that does not exist
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DELETE FROM simpleErrorTable1 WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
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

-- Error: deleting values from a table that does not exist
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DELETE FROM simpleErrorTable1 WHERE c = 1;
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
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: deleting values from a table that does not exist
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    DELETE FROM simpleErrorTable1 WHERE c = 1;
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

-- Error: deleting values from a table that does not exist
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DELETE FROM simpleErrorTable1 WHERE c = 1;
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

-- Error: deleting values from a table that does not exist
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        DELETE FROM simpleErrorTable1 WHERE c = 1;
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


-- Error: syntax error
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
GO
select * from simpleErrorTable ORDER BY c
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple batch with commit transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple batch with rollback transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple batch with rollback transaction and rollback to savepoint
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    save tran sp1;
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    rollback tran sp1;
rollback tran;
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple procedure
create procedure simpleErrorProc1
as 
begin 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
end
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple batch with nested transaction
begin tran; 
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
    begin tran; 
        UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
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

-- Error: syntax error
-- simple procedure with transaction
create procedure simpleErrorProc1
as 
begin 
    begin tran; 
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
            begin tran; 
                UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
            commit tran; 
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
    commit tran; 
end
GO
exec simpleErrorProc1
GO
select * from simpleErrorTable ORDER BY c
GO
select @@trancount
GO
drop procedure simpleErrorProc1
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- simple procedure with transaction started inside procedure but ended outside procedure
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
        INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
end
GO
exec simpleErrorProc1
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

-- Error: syntax error
-- simple procedure with transaction started outside procedure but ended inside procedure through commit
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    commit tran;
end
GO
begin tran
GO
exec simpleErrorProc1
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

-- Error: syntax error
-- simple procedure with transaction started outside procedure but ended inside procedure through rollback
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran;
end
GO
begin tran
GO
exec simpleErrorProc1
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

-- Error: syntax error
-- nested procedure (level 2)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
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
select * from simpleErrorTable ORDER BY c
GO
drop procedure simpleErrorProc1
GO
drop procedure simpleErrorProc2
GO
truncate table simpleErrorTable
GO

-- Error: syntax error
-- nested procedure (level 3)
create procedure simpleErrorProc1
as
begin
    INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
    UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
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

-- Error: syntax error
-- nested procedure with commit transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
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

-- Error: syntax error
-- nested procedure with rollback transaction
create procedure simpleErrorProc1
as
begin
    begin tran;
        INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1);
        UPDATE1 simpleErrorTable SET c = NULL WHERE c = 1;
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
-- simple batch
INSERT INTO simpleErrorTable VALUES ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
EXECUTE sp_executesql N'UPDATE simpleErrorTable SET a = convert(int, ''abc'') WHERE c = 1;';
INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
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
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
commit tran;
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
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5); 
rollback tran;
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
    INSERT INTO simpleErrorTable(a, b, c, e, f, g) VALUES ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
    rollback tran sp1; 
rollback tran;
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

-- cleanup
SET XACT_ABORT OFF;
GO

drop table simpleErrorTable
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
GO
