SELECT schema_id('public')
GO

SELECT schema_id('pg_toast')
GO

SELECT schema_id(NULL)
GO

SELECT schema_id(1)
GO

SELECT schema_id('fake_schemaname')
GO

-- empty schema name should return NULL
SELECT schema_id('')
GO

SELECT schema_name(schema_id())
GO

SELECT schema_name(schema_id('dbo'))
GO

SELECT schema_name(99)
GO

SELECT schema_name(2200)
GO

SELECT schema_name(-1)
GO

SELECT schema_name(0)
GO

SELECT schema_name(1)
GO

SELECT schema_name(123412341234)
GO

SELECT schema_name(NULL)
GO

SELECT schema_name('asdf')
GO

SELECT schema_name()
GO

SELECT * from babel_3836_f1();
GO

SELECT * from babel_3836_v1;
GO

EXEC babel_3836_p1;
GO