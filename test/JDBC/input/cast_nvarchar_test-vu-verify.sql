-- TEST CASE 1: creating a table and then calling hashbytes for nvarchar and varchar input
insert into TestHash values('value1', 'value1');
GO

SELECT DATALENGTH( nvarchar_data) as nvarchar_data_datalength
        , LEN( nvarchar_data) AS nvarchar_data_len
        , DATALENGTH( varchar_data) as varchar_data_btyes_datalength
        , LEN( varchar_data) AS varchar_data_len
        , * 
from TestHash;
GO
-- TEST CASE 2: Casting nvarchar and varchar with different algorithms using Hashbytes
SELECT hashbytes( 'sha1', 'test string' ) as vary_string, hashbytes( 'sha1', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'MD2', 'test string' ) as vary_string, hashbytes( 'MD2', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'MD4', 'test string' ) as vary_string, hashbytes( 'MD4', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'MD5', 'test string' ) as vary_string, hashbytes( 'MD5', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'SHA2_256', 'test string' ) as vary_string, hashbytes( 'SHA2_256', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'SHA2_512', 'test string' ) as vary_string, hashbytes( 'SHA2_512', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'SHA', 'test string' ) as vary_string, hashbytes( 'SHA', N'test string' ) as unicode_string
GO

SELECT hashbytes( 'sha1', 'test string')
GO
--TEST CASE 3: testing hashbytes via casting a varchar to nvarchar 
SELECT hashbytes('sha1',cast('test string' as sys.nvarchar))
GO

--TEST CASE 4: Casting function for nvarchar to varbinary

SELECT cast(N'test string' as varbinary);
GO

SELECT cast(cast(cast('ab' AS nvarchar(10)) as varbinary(2)) as nvarchar(2));
GO

