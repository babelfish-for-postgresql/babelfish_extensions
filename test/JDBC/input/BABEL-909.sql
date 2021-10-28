-- Test NEWSEQUENTIALID() as column default constraint
CREATE TABLE new_sequential_id_table_1 (ColumnA uniqueidentifier DEFAULT NEWSEQUENTIALID());
go
-- Test NEWSEQUENTIALID() in alter table 
ALTER TABLE new_sequential_id_table_1 ADD ColumnB uniqueidentifier DEFAULT NEWSEQUENTIALID();
go
-- Test NEWSEQUENTIALID() as column default constraint with wrong type (shoudl fail)
CREATE TABLE new_sequential_id_table_2 (ColumnA varchar(60) DEFAULT NEWSEQUENTIALID());
go
-- Test NEWSEQUENTIALID() in SELECT statement (shoudl fail)
SELECT pg_typeof(newsequentialid());
go
-- Test NEWSEQUENTIALID() as scalar function (should fail)
CREATE FUNCTION foo(@i uniqueidentifier)
RETURNS uniqueidentifier
AS
BEGIN
    RETURN @i
END;
go
CREATE TABLE new_sequential_id_table_3 (ColumnA uniqueidentifier DEFAULT foo(NEWSEQUENTIALID()));
go
DROP TABLE new_sequential_id_table_1;
go
DROP TABLE new_sequential_id_table_2;
go
DROP TABLE new_sequential_id_table_3;
go
DROP FUNCTION foo;
go
