use master;
go

CREATE TABLE load(load int);
go
INSERT INTO load values (1);
go
SELECT load FROM load;
go
DROP TABLE load;
go
