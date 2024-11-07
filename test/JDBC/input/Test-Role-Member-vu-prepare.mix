CREATE LOGIN test_role_member_l1 WITH PASSWORD = '12345678';
GO

CREATE ROLE test_role_member_r1;
GO

CREATE USER test_role_member_u1 FOR LOGIN test_role_member_l1;
GO

CREATE TABLE test_role_member_t1(a INT);
GO

GRANT SELECT ON OBJECT::test_role_member_t1 to test_role_member_r1;
GO

-- tsql		user=test_role_member_l1		password=12345678
SELECT * FROM test_role_member_t1;
GO

-- tsql
ALTER ROLE test_role_member_r1 ADD MEMBER test_role_member_u1;
GO

-- tsql		user=test_role_member_l1		password=12345678
SELECT * FROM test_role_member_t1;
GO

-- tsql
use master
GO
