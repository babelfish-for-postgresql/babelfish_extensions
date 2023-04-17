--Cleanup
DROP TYPE IF EXISTS test1.null_check1
Go

DROP TYPE IF EXISTS test1.null_check2
Go

DROP TYPE IF EXISTS test2.null_check1
Go

DROP TYPE IF EXISTS test2.null_check2
Go

DROP SCHEMA IF EXISTS test1
GO

DROP SCHEMA IF EXISTS test2
GO

--Setup
Create schema test1
Go

Create schema test2
Go

Create type test1.null_check1 FROM varchar(11) NOT NULL ;
GO

Create type test1.null_check2 FROM int  NULL ;
GO

Create type test2.null_check1 FROM varchar(11)  NULL ;
GO

Create type test2.null_check2 FROM int  NOT NULL ;
GO

-- =============== AllowsNull ===============
Select typeproperty('sys.int','allowsnull')
Go

Select typeproperty('pg_catalog.int','allowsnull')
Go

Select typeproperty('pg_catalog.int','allowsnul')
GO

Select typeproperty('pg_catalog.int',' allowsnull   ')
Go

Select typeproperty('test1.null_check1','allowsnull')
GO

Select typeproperty('test1.null_check2','allowsnull')
GO

Select typeproperty('test2.null_check1','allowsnull')
GO

Select typeproperty('test2.null_check2','allowsnull')
GO

-- =============== Precision ===============

Select typeproperty('sys.int','precision')
Go

Select typeproperty('pg_catalog.int','precision')
Go

Select typeproperty('pg_catalog.int','precisusn')
GO

Select typeproperty('pg_catalog.int',' precision   ')
Go

Select typeproperty('test1.null_check1','precision')
GO

Select typeproperty('test1.null_check2','precision')
GO

Select typeproperty('test2.null_check1','precision')
GO

Select typeproperty('test2.null_check2','precision')
GO

-- ===============Scale===============

Select typeproperty('sys.int','scale')
Go

Select typeproperty('pg_catalog.int','scale')
Go

Select typeproperty('pg_catalog.int','scael')
GO

Select typeproperty('pg_catalog.int',' scale   ')
Go

Select typeproperty('sys.char',' scale   ')
Go

Select typeproperty('sys.money',' scale   ')
Go

Select typeproperty('test1.null_check1','scale')
GO

Select typeproperty('test1.null_check2','scale')
GO

Select typeproperty('test2.null_check1','scale')
GO

Select typeproperty('test2.null_check2','scale')
GO

-- ===============OwnerId===============

SELECT CASE
    WHEN typeproperty('sys.int','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('pg_catalog.int','ownerid') IS NOT  NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('pg_catalog.int','ownerdi') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('pg_catalog.int',' ownerid   ') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('test1.null_check1','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('test1.null_check2','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('test2.null_check1','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('test2.null_check2','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO


--Cleanup
DROP TYPE test1.null_check1
Go

DROP TYPE test1.null_check2
Go

DROP TYPE test2.null_check1
Go

DROP TYPE test2.null_check2
Go

DROP SCHEMA test1
GO

DROP SCHEMA test2
GO
