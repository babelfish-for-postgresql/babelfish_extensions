CREATE PROC babel_sp_columns_managed_dep_vu_prepare_p1 @Catalog AS sys.SYSNAME = NULL, @Owner AS sys.SYSNAME = NULL, @Table AS sys.SYSNAME = NULL, @Column AS sys.SYSNAME = NULL, @SchemaType AS sys.SYSNAME = 0
AS
BEGIN
	EXEC sp_columns_managed @Catalog, @Owner, @Table, @Column, @SchemaType;
END
GO
