use master
go

DROP VIEW IF EXISTS babel_3402_v1
go

CREATE VIEW babel_3402_v1 AS SELECT suser_sid(-10)
go

SELECT suser_sid(-10)
go
