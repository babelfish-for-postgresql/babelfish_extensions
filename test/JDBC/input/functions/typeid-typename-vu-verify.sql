SELECT TYPE_NAME(TYPE_ID('typeid_typename_vu_prepare_t1'));
GO

SELECT TYPE_NAME(TYPE_ID('typeid_typename_vu_prepare_s1.typeid_typename_vu_prepare_t1'));
GO

SELECT TYPE_NAME(TYPE_ID('dbo.typeid_typename_vu_prepare_t1'));
GO

-- It should give null as new type is created in dbo
SELECT TYPE_ID('sys.typeid_typename_vu_prepare_t1');
GO

SELECT TYPE_NAME(TYPE_ID('typeid_typename_vu_prepare_t2'));
GO

SELECT TYPE_NAME(TYPE_ID('datetime'));
GO

SELECT TYPE_NAME(TYPE_ID('INT'));
GO

SELECT TYPE_NAME(TYPE_ID('pg_catalog.INT'));
GO

-- sys.int should give same type_id as of pg_catalog
SELECT TYPE_NAME(TYPE_ID('sys.INT'));
GO

-- It should throw error
SELECT TYPE_NAME();
GO

-- It should give null on wrong type_id
SELECT TYPE_NAME(12083980);
GO

-- It should throw error on wrong input format
SELECT TYPE_NAME('test');
GO

-- It should give null on wrong type_name
SELECT TYPE_NAME(TYPE_ID('test'));
GO

-- It should throw error
SELECT TYPE_ID();
GO

-- It should give null on wrong type_name
SELECT TYPE_ID('test');
GO

-- It should give null on wrong type_name format
SELECT TYPE_ID(21986389);
GO

-- It should give null on wrong type_id
SELECT TYPE_ID(TYPE_NAME(13134932));
GO

SELECT TYPE_NAME(TYPE_ID('   pg_catalog   .   text  '));
GO

SELECT TYPE_NAME(TYPE_ID('  text     '));
GO

