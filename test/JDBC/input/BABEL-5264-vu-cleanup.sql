-- BABEL-5264: Cleanup for sp_tablecollations_100 tests
-- Cleanup UDTs created for non-ENR tests
DROP TYPE IF EXISTS dbo.TestVarcharType1
GO
DROP TYPE IF EXISTS dbo.TestVarcharType2
GO
DROP TYPE IF EXISTS dbo.TestVarcharType3
GO
DROP TYPE IF EXISTS dbo.TestVarcharType4
GO
DROP TYPE IF EXISTS dbo.TestIntType
GO
