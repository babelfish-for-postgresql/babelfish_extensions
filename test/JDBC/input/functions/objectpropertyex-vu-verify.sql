-- Check for correct case
SELECT CASE
    WHEN OBJECTPROPERTY(OBJECT_ID('ownerid_schema.ownerid_table'), 'OwnerId')  = (SELECT principal_id 
            FROM sys.database_principals
            WHERE name = CURRENT_USER)
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

-- Invalid property ID (should return NULL)
SELECT OBJECTPROPERTY(0, 'OwnerId')
GO

-- =============== BaseType ===============

-- Tests valid cases

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_table'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_view'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_function'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('basetype_proc'), 'BaseType')
GO

-- Tests invalid object
SELECT OBJECTPROPERTYEX(0, 'BaseType')
GO

-- =============== Special Input Cases ===============

-- Tests special input cases
SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'BASETYPE')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'basetype')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('specialinput_table'), 'BASETYPE       ')
GO
