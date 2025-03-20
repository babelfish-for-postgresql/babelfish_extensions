-- setup
CREATE TABLE parent(a int primary key);
GO
CREATE TABLE child(b int, foreign key (b) references parent(a) ON UPDATE CASCADE);
GO
CREATE TRIGGER trig1 on child AFTER UPDATE AS BEGIN SELECT 1 END
GO
INSERT INTO parent values(1)
INSERT INTO child values(1)
GO

-- check metadata
select name,is_disabled from sys.triggers
GO

-- check if trigger enabled, as well as fkey action works
UPDATE parent set a=2 where a=1
GO
SELECT * from parent;select * from child;
GO

ALTER TABLE child disable trigger all
GO

-- check metadata
select name,is_disabled from sys.triggers
GO

-- check if only trigger disabled and not fkey action
UPDATE parent set a=3 where a=2
GO
SELECT * from parent;select * from child;
GO


ALTER TABLE child enable trigger all
GO

-- check metadata
select name,is_disabled from sys.triggers
GO

-- check  if trigger renabled
UPDATE parent set a=4 where a=3
GO
SELECT * from parent;select * from child;
GO

DISABLE trigger all on child;
GO

-- check metadata
select name,is_disabled from sys.triggers
GO

-- check  if only trigger disabled and not fkey action
UPDATE parent set a=5 where a=4
GO
SELECT * from parent;select * from child;
GO

ENABLE trigger all on child;
GO

-- check metadata
select name,is_disabled from sys.triggers
GO

-- check  if trigger renabled
UPDATE parent set a=6 where a=5
GO
SELECT * from parent;select * from child;
GO

-- cleanup
DROP TABLE child;DROP TABLE parent;
GO