CREATE TABLE babel_539OldTable(col1 int , name varchar(20));
GO

INSERT INTO babel_539OldTable VALUES (10, 'user1') , (20, 'user2'), (30, 'user3');
GO

CREATE PROC babel_539_prepare_proc
AS
SELECT col1, name, IDENTITY(int, 1,2) AS id_num INTO babel_539NewTable_proc FROM babel_539OldTable order by col1;
GO