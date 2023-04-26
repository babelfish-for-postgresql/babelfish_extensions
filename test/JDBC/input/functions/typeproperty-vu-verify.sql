-- =============== AllowsNull ===============
Select typeproperty('sys.int','allowsnull')
Go

Select typeproperty('pg_catalog.int','allowsnull')
Go

Select typeproperty('pg_catalog.int','allowsnul')
GO

Select typeproperty('pg_catalog.int',' allowsnull   ')
Go

Select typeproperty('typeproperty_test1.null_check1','allowsnull')
GO

Select typeproperty('typeproperty_test1.null_check2','allowsnull')
GO

Select typeproperty('typeproperty_test2.null_check1','allowsnull')
GO

Select typeproperty('typeproperty_test2.null_check2','allowsnull')
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

Select typeproperty('typeproperty_test1.null_check1','precision')
GO

Select typeproperty('typeproperty_test1.null_check2','precision')
GO

Select typeproperty('typeproperty_test2.null_check1','precision')
GO

Select typeproperty('typeproperty_test2.null_check2','precision')
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

Select typeproperty('typeproperty_test1.null_check1','scale')
GO

Select typeproperty('typeproperty_test1.null_check2','scale')
GO

Select typeproperty('typeproperty_test2.null_check1','scale')
GO

Select typeproperty('typeproperty_test2.null_check2','scale')
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
    WHEN typeproperty('typeproperty_test1.null_check1','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('typeproperty_test1.null_check2','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('typeproperty_test2.null_check1','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

SELECT CASE
    WHEN typeproperty('typeproperty_test2.null_check2','ownerid') IS NOT NULL
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO
