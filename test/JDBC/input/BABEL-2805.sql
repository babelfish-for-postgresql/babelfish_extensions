SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8), (9, 10) ) AS MyTable(a, b);  
GO

create table t1 (col1 nvarchar(20), col2 nvarchar(20))
go

insert into t1 values ('name', '42')
go

select t.* from t1
CROSS APPLY
(
    VALUES
        (1, 'col1', col1),
        (2, 'col2', col2)
) t(id, [name], [value])
go

drop table t1
go

CREATE TABLE t1(  
    SalesReasonID int IDENTITY(1,1) NOT NULL,  
    Name varchar(max) NULL ,  
    ReasonType varchar(max) NOT NULL DEFAULT 'Not Applicable' );  
GO

INSERT INTO t1   
VALUES ('Recommendation','Other'), ('Advertisement', DEFAULT), (NULL, 'Promotion');  

SELECT * FROM t1;  
GO

DROP TABLE t1;
GO

-- Regression tests for CROSS JOIN
create table t1 (a int, b int)
create table t2 (c int, d int)
insert into t1 values (1, 1),(2, 2)
insert into t2 values (3, 3),(4, 4)
go

select * from t1 cross join (values (3, 3),(4,4)) t2(c1, c2)
go

select * from t1 cross join t2
go

select * from t1 cross join (select * from t2) t2(c1, c2)
go

drop table t1
go

drop table t2
go
