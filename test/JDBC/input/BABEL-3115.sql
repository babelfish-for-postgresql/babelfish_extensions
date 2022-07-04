CREATE TABLE t
(
c1 int IDENTITY(1,1) PRIMARY KEY,
c2 varchar(20) UNIQUE not null
);
GO

INSERT INTO t(c2) VALUES ('Joe'), ('Steve');
GO

SELECT * FROM t
go

CREATE TRIGGER TR_t ON t INSTEAD OF INSERT
AS
DECLARE @c1 int, @c2 varchar(20);
SELECT @c1 = c1, @c2 = c2 FROM inserted;
INSERT INTO t (c2) VALUES(@c2 + '2') --BUG: This INSERT disappears
GO

INSERT INTO t(c2) VALUES ('Joe')
GO

SELECT * FROM t
GO

drop trigger TR_t
GO

drop table t
GO