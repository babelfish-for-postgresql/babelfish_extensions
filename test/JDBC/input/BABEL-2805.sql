SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8), (9, 10) ) AS MyTable(a, b);  
GO

create table t1 (col1 nvarchar(20), col2 nvarchar(20))
go

insert into t1 values ('name', '42')
go

select t.* from t1
CROSS APPLY
(
	VALUES
		(1, 'col1', col1),
		(2, 'col2', col2)
) t(id, [name], [value])
go

drop table t1
go

CREATE TABLE t1(  
    SalesReasonID int IDENTITY(1,1) NOT NULL,  
    Name varchar(max) NULL ,  
    ReasonType varchar(max) NOT NULL DEFAULT 'Not Applicable' );  
GO

INSERT INTO t1   
VALUES ('Recommendation','Other'), ('Advertisement', DEFAULT), (NULL, 'Promotion');  

SELECT * FROM t1;  
GO

DROP TABLE t1;
GO

CREATE TABLE t1 ([Id] int, [Audit.InsertOnly] bit, [Audit.Id] int, [Audit.Timestamp] int, [Audit.Action] varchar, [CampaignId] int, [Type] int, [RangeStart] int, [RangeEnd] int)
INSERT INTO t1 VALUES (1, 1, 1, 1, 'I', 1, 1, 1, 1)
GO

CREATE FUNCTION f1 (@p1 [int],
 @p2 [BIT])
RETURNS TABLE
AS
RETURN
WITH
temp_table_1
AS
(
	SELECT	alias_2.[Audit.Id],
			alias_2.[Audit.InsertOnly]
	FROM t1 alias_1
		INNER JOIN t1 alias_2
	ON (alias_2.[Id] = alias_1.[Id] OR (alias_2.[Id] IS NULL AND alias_1.[Id] IS NULL))
		AND alias_2.[Audit.InsertOnly] = alias_1.[Audit.InsertOnly]
	WHERE alias_1.[Audit.Id] = @p1
		AND alias_1.[Audit.InsertOnly] = @p2
),
temp_table_2
AS
(
	SELECT	t1.[Audit.Id] [Audit.Id],
			t1.[Audit.InsertOnly] [Audit.InsertOnly],
			t1.[Audit.Timestamp] [Audit.Timestamp],
			t1.[Audit.Action] [Audit.Action],
			t1.[Id] [CurrentRow.Id],
			t1.[CampaignId] [CurrentRow.CampaignId],
			t1.[Type] [CurrentRow.Type],
			t1.[RangeStart] [CurrentRow.RangeStart],
			t1.[RangeEnd] [CurrentRow.RangeEnd],
			LAG(t1.[Id])
				OVER (PARTITION BY t1.[Id]
				ORDER BY t1.[Audit.Timestamp],
				t1.[Audit.Id]) [PreviousRow.Id],
			LAG(t1.[CampaignId])
				OVER (PARTITION BY t1.[Id]
				ORDER BY t1.[Audit.Timestamp],
				t1.[Audit.Id]) [PreviousRow.CampaignId],
			LAG(t1.[Type])
				OVER (PARTITION BY t1.[Id]
				ORDER BY t1.[Audit.Timestamp],
				t1.[Audit.Id]) [PreviousRow.Type],
			LAG(t1.[RangeStart])
				OVER (PARTITION BY t1.[Id]
				ORDER BY t1.[Audit.Timestamp],
				t1.[Audit.Id]) [PreviousRow.RangeStart],
			LAG(t1.[RangeEnd])
				OVER (PARTITION BY t1.[Id]
				ORDER BY t1.[Audit.Timestamp],
				t1.[Audit.Id]) [PreviousRow.RangeEnd]
	FROM t1
		INNER JOIN temp_table_1
	ON temp_table_1.[Audit.Id] = t1.[Audit.Id]
		AND temp_table_1.[Audit.InsertOnly] = t1.[Audit.InsertOnly]
),
temp_table_3
AS
(
	SELECT	temp_table_2.[Audit.Id] [Audit.Id],
			temp_table_2.[Audit.InsertOnly] [Audit.InsertOnly],
			temp_table_2.[Audit.Timestamp] [Audit.Timestamp],
			temp_table_2.[Audit.Action] [Audit.Action],
			[Columns].[Name] [Audit.ColumnName],
			CASE WHEN temp_table_2.[Audit.Action] = 'I' THEN NULL
			WHEN temp_table_2.[Audit.Action] = 'D' AND [Columns].[Name] = 'Id' THEN CAST(temp_table_2.[CurrentRow.Id] AS [VARCHAR](MAX))
			WHEN temp_table_2.[Audit.Action] = 'D' AND [Columns].[Name] = 'CampaignId' THEN CAST(temp_table_2.[CurrentRow.CampaignId] AS [VARCHAR](MAX))
			WHEN temp_table_2.[Audit.Action] = 'D' AND [Columns].[Name] = 'Type' THEN CAST(temp_table_2.[CurrentRow.Type] AS [VARCHAR](MAX))
			WHEN temp_table_2.[Audit.Action] = 'D' AND [Columns].[Name] = 'RangeStart' THEN CAST(temp_table_2.[CurrentRow.RangeStart] AS [VARCHAR](MAX))
			WHEN temp_table_2.[Audit.Action] = 'D' AND [Columns].[Name] = 'RangeEnd' THEN CAST(temp_table_2.[CurrentRow.RangeEnd] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'Id' THEN CAST(temp_table_2.[PreviousRow.Id] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'CampaignId' THEN CAST(temp_table_2.[PreviousRow.CampaignId] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'Type' THEN CAST(temp_table_2.[PreviousRow.Type] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'RangeStart' THEN CAST(temp_table_2.[PreviousRow.RangeStart] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'RangeEnd' THEN CAST(temp_table_2.[PreviousRow.RangeEnd] AS [VARCHAR](MAX)) END [Audit.OldValue],
			CASE WHEN temp_table_2.[Audit.Action] = 'D' THEN NULL
			WHEN [Columns].[Name] = 'Id' THEN CAST(temp_table_2.[CurrentRow.Id] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'CampaignId' THEN CAST(temp_table_2.[CurrentRow.CampaignId] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'Type' THEN CAST(temp_table_2.[CurrentRow.Type] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'RangeStart' THEN CAST(temp_table_2.[CurrentRow.RangeStart] AS [VARCHAR](MAX))
			WHEN [Columns].[Name] = 'RangeEnd' THEN CAST(temp_table_2.[CurrentRow.RangeEnd] AS [VARCHAR](MAX)) END [Audit.NewValue]
	FROM temp_table_2
		CROSS JOIN (VALUES	
						(CAST('Id' AS [SYSNAME])),
						(CAST('CampaignId' AS [SYSNAME])),
						(CAST('Type' AS [SYSNAME])),
						(CAST('RangeStart' AS [SYSNAME])),
						(CAST('RangeEnd' AS [SYSNAME]))
					) [Columns]([Name])
)
SELECT temp_table_3.[Audit.ColumnName],
temp_table_3.[Audit.OldValue],
temp_table_3.[Audit.NewValue]
FROM temp_table_3
WHERE temp_table_3.[Audit.Id] = @p1
AND temp_table_3.[Audit.InsertOnly] = @p2;
GO

-- Regression tests for CROSS JOIN
SELECT * FROM f1(1, 1)
go

DROP FUNCTION f1
GO

DROP TABLE t1
GO

create table t1 (a int, b int)
create table t2 (c int, d int)
insert into t1 values (1, 1),(2, 2)
insert into t2 values (3, 3),(4, 4)
go

select * from t1 cross join (values (3, 3),(4,4)) t2(c1, c2)
go

select * from t1 cross join t2
go

select * from t1 cross join (select * from t2) t2(c1, c2)
go

drop table t1
go

drop table t2
go
