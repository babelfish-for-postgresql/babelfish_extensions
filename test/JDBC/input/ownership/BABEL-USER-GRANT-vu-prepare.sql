CREATE DATABASE babel_5890_db
GO

USE babel_5890_db
GO

-- Create login and verify login is mapped to guest role, create user and verify login mapping is changed from guest role to user role
CREATE LOGIN babel_5890_role_vu_prepare_r1 WITH PASSWORD = '1234';
CREATE USER babel_5890_role_vu_prepare_r1 FOR LOGIN babel_5890_role_vu_prepare_r1;
DROP USER babel_5890_role_vu_prepare_r1;
GO

-- Alter user login and verify login mapping is changed from guest role to user role
CREATE USER babel_5890_role_vu_prepare_r2 FOR LOGIN babel_5890_role_vu_prepare_r1;
CREATE LOGIN babel_5890_role_vu_prepare_r2 WITH PASSWORD = '1234';
GO

CREATE PROC babel_role_vu_prepare_role_mapping AS
BEGIN
	SELECT
		r.rolname AS role_name,
		m.rolname AS member_name,
		CASE
			WHEN (g.rolname IN ('bbf_role_admin')) then true else false
		END AS grantor,
		am.admin_option, 
		am.inherit_option, 
		am.set_option
	FROM pg_auth_members am
	JOIN pg_roles r ON am.roleid = r.oid
	JOIN pg_roles m ON am.member = m.oid
	JOIN pg_roles g ON am.grantor = g.oid
	WHERE r.rolname IN ('babel_5890_db_guest', 'babel_5890_db_babel_5890_role_vu_prepare_r1', 'babel_5890_db_babel_5890_role_vu_prepare_r2') AND m.rolname IN ('babel_5890_role_vu_prepare_r1', 'babel_5890_role_vu_prepare_r2')
	ORDER BY r.rolname;
END
GO
