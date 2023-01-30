drop user [babel\aduser];
GO

drop user test_user;
GO

drop login [babel\aduser];
GO

drop user [babel\aduser2];
GO

drop login [babel\aduser2];
GO

drop user [abc];
GO

drop login [babel\aduser3];
GO

drop user pass;
GO

drop login pass;
GO

use testdb;
GO

drop user [babel\testuser];
GO

drop login [babel\testuser];
GO

use master;
GO

drop role test_role;
GO

drop database testdb;
GO