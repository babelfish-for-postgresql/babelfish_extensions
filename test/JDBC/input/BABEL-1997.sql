--create
CREATE TABLE t1997_1(c1 int primary key, c2 int)
GO
CREATE TABLE t1997_2(c1 int primary key, c2 int, constraint fk foreign key (c2) references t1997_1(c1))
GO
INSERT INTO t1997_1 VALUES(1, 10)
INSERT INTO t1997_2 VALUES(100, 1)
GO
--generate error
begin tran
        begin try
                TRUNCATE TABLE t1997_1;
        end try
        begin catch
                select xact_state();
                DROP TABLE t1997_2
                DROP TABLE t1997_1
        end catch
go

--clean
DROP TABLE t1997_2
GO
DROP TABLE t1997_1
GO
