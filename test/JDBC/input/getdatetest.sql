-- NOTE: Each test is expected to take a lot of time
-- We do not need Upgrade tests for these function
-- We can only test the stability of this function in the framework since the results are dynamic

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
go

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
go

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
go

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
go

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
go
