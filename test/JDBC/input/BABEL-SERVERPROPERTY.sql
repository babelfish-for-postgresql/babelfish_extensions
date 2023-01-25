-- test serverproperty() function
-- invalid property name, should reutnr NULL
select serverproperty('invalid property');
go
-- valid supported properties
select serverproperty('collation');
go
select 'true' where serverproperty('collationId') >= 0;
go
select serverproperty('IsSingleUser');
go
select serverproperty('ServerName');
go

-- BABEL-1286
SELECT SERVERPROPERTY('babelfish');
go

-- BABEL-3587
CREATE PROCEDURE BABEL_3587_proc (@BabelfishVersion VARCHAR(50), @productlevel VARCHAR(50))
AS BEGIN
    DECLARE @minor_version VARCHAR(50);
    DECLARE @productlevel_number VARCHAR(50);

    SELECT @minor_version = value FROM (SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) idx  
        FROM STRING_SPLIT(@BabelfishVersion, '.')) t 
        WHERE idx  = 2
    IF(@minor_version = '0')
    BEGIN
        IF(@productlevel = 'RTM') SELECT 'pass'
        ELSE SELECT 'fail'
    END
    ELSE
    BEGIN
        SELECT @productlevel_number = substring(@productlevel, 3, (len(@productlevel) - 1));
        if (@productlevel like 'SP%' AND @BabelfishVersion like '%.' + @productlevel_number)
            SELECT 'pass'
        ELSE SELECT 'fail'
    END
END;
GO


EXEC BABEL_3587_proc '2.0.0','RTM'
GO

EXEC BABEL_3587_proc '2.2.0','RTM'
GO

EXEC BABEL_3587_proc '2.2.0','SP2.0'
GO

EXEC BABEL_3587_proc '2.2.0','SP2.1'
GO

DECLARE @BabelfishVersion VARCHAR(50);
DECLARE @productlevel VARCHAR(50);
SELECT @BabelfishVersion = serverproperty('BabelfishVersion');
SELECT @productlevel = serverproperty('productlevel');
EXEC BABEL_3587_proc @BabelfishVersion,@productlevel
GO

DROP PROCEDURE BABEL_3587_proc
GO