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

-- It should give null
SELECT TYPE_NAME(TYPE_ID('   pg_catalog   .   text  '));
GO

-- It should give null
SELECT TYPE_NAME(TYPE_ID('  text     '));
GO

SELECT TYPE_NAME(TYPE_ID('text     '));
GO

SELECT TYPE_NAME(TYPE_ID('"ab.d"."my.type"'));
GO

SELECT TYPE_NAME(TYPE_ID('"ab.d".[my.type]'));
GO

SELECT TYPE_NAME(TYPE_ID('[ab.d].[my.type]'));
GO

SELECT TYPE_NAME(TYPE_ID('[ab.d]."my.type"'));
GO

SELECT TYPE_NAME(TYPE_ID('"ab.d".type'));
GO

SELECT TYPE_NAME(TYPE_ID('[ab.d].type'));
GO

SELECT TYPE_NAME(TYPE_ID('ab."my.type"'));
GO

SELECT TYPE_NAME(TYPE_ID('ab.[my.type]'));
GO

SELECT TYPE_NAME(TYPE_ID('ab.type'));
GO

SELECT TYPE_NAME(TYPE_ID('"my.type"'));
GO

SELECT TYPE_NAME(TYPE_ID('abCDE'));
GO

SELECT TYPE_NAME(TYPE_ID('abcde'));
GO

SELECT TYPE_NAME(TYPE_ID('ABCDE'));
GO

SELECT TYPE_NAME(TYPE_ID('" my.,-][type "'));
GO

SELECT TYPE_NAME(TYPE_ID('您对'));
GO

SELECT TYPE_NAME(TYPE_ID('您对中的车色内饰选'));
GO

SELECT TYPE_NAME(TYPE_ID('ぁあぃいぅうぇ'));
GO

SELECT TYPE_NAME(TYPE_ID('ㄴㄷㄹㅁㅂㅅ'));
GO

SELECT TYPE_NAME(TYPE_ID('ĄĆĘŁŃÓŚŹŻąćęłńóśź'));
GO

SELECT TYPE_NAME(TYPE_ID('وزحطيكلم'));
GO

SELECT TYPE_NAME(TYPE_ID('αΒβΓγΔδΕε'));
GO

-- It should return null as type_id does not support three part name
SELECT TYPE_ID('master.dbo.typeid_typename_vu_prepare_t1');
GO

SELECT TYPE_ID('input_longer_than_4000_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1');
GO

SELECT TYPE_NAME(TYPE_ID('int'));
GO

SELECT TYPE_NAME(TYPE_ID('dbo.bigint'));
GO

SELECT TYPE_NAME(TYPE_ID('bigint'));
GO

SELECT TYPE_NAME(TYPE_ID('myint'));
GO

SELECT TYPE_NAME(TYPE_ID('dbo.myint'));
GO

SELECT TYPE_NAME(TYPE_ID('typeid_typename_vu_prepare_s1.myint'));
GO

