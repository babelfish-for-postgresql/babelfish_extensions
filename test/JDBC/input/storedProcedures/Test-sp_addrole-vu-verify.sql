-- tsql
-- Throws an error when role exists
Exec sp_addrole 'sp_addrole_r1';
GO

CREATE ROLE sp_addrole_r1;
GO
