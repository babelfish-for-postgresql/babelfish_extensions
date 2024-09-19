Create procedure sysdatetime_dep_proc
AS 
    WITH
        Pass0 as (select sys.sysdatetime() as C union all select sys.sysdatetime()), --2 rows
        Pass1 as (select sys.sysdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
        Pass2 as (select sys.sysdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
        Pass3 as (select sys.sysdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
        Pass4 as (select sys.sysdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
        Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetime()
GO

Create procedure sysdatetimeoffset_dep_proc
AS 
    WITH
    Pass0 as (select sys.sysdatetimeoffset() as C union all select sys.sysdatetimeoffset()), --2 rows
    Pass1 as (select sys.sysdatetimeoffset() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysdatetimeoffset() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysdatetimeoffset() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysdatetimeoffset() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetimeoffset()
GO

Create procedure sysutcdatetime_dep_proc
AS 
    WITH
    Pass0 as (select sys.sysutcdatetime() as C union all select sys.sysutcdatetime()), --2 rows
    Pass1 as (select sys.sysutcdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysutcdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysutcdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysutcdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sysutcdatetime()
GO

Create procedure getdate_dep_proc 
AS 
    WITH
    Pass0 as (select sys.getdate() as C union all select sys.getdate()), --2 rows
    Pass1 as (select sys.getdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getdate()
GO

Create procedure getutcdate_dep_proc
AS
    WITH
    Pass0 as (select sys.getutcdate() as C union all select sys.getutcdate()), --2 rows
    Pass1 as (select sys.getutcdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getutcdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getutcdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getutcdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getutcdate()
GO

Create view sysdatetime_dep_view
AS 
    WITH
        Pass0 as (select sys.sysdatetime() as C union all select sys.sysdatetime()), --2 rows
        Pass1 as (select sys.sysdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
        Pass2 as (select sys.sysdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
        Pass3 as (select sys.sysdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
        Pass4 as (select sys.sysdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
        Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetime()
GO

Create view sysdatetimeoffset_dep_view
AS 
    WITH
    Pass0 as (select sys.sysdatetimeoffset() as C union all select sys.sysdatetimeoffset()), --2 rows
    Pass1 as (select sys.sysdatetimeoffset() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysdatetimeoffset() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysdatetimeoffset() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysdatetimeoffset() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetimeoffset()
GO

Create view sysutcdatetime_dep_view
AS 
    WITH
    Pass0 as (select sys.sysutcdatetime() as C union all select sys.sysutcdatetime()), --2 rows
    Pass1 as (select sys.sysutcdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysutcdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysutcdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysutcdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sysutcdatetime()
GO

Create view getdate_dep_view
AS
    WITH
    Pass0 as (select sys.getdate() as C union all select sys.getdate()), --2 rows
    Pass1 as (select sys.getdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getdate()
GO

Create view getutcdate_dep_view
AS
    WITH
    Pass0 as (select sys.getutcdate() as C union all select sys.getutcdate()), --2 rows
    Pass1 as (select sys.getutcdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getutcdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getutcdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getutcdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getutcdate()
GO
