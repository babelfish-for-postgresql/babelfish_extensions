USE master
go

-- Should be blocked
CREATE USER babel_2410_user
go

-- Should be blocked
CREATE ROLE babel_2410_role
go

CREATE PROC babel_2410_proc AS
SELECT 123
go

-- Should be blocked
GRANT ALL ON babel_2410_proc TO jdbc_user
go

DROP PROC babel_2410_proc
go

DROP USER babel_2410_user
go

DROP ROLE babel_2410_role
go
