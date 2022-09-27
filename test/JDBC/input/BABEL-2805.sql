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

CREATE FUNCTION fn_GetMaxDate
(
	@Date1					datetime2(6),
	@Date2					datetime2(6),
	@Date3					datetime2(6),
	@Date4					datetime2(6),
	@Date5					datetime2(6)
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		MAX(d.MaxDate)		AS MaxDate
	FROM
		(
			VALUES
				(ISNULL(@Date1, '1900/01/01')),
				(ISNULL(@Date2, '1900/01/01')),
				(ISNULL(@Date3, '1900/01/01')),
				(ISNULL(@Date4, '1900/01/01')),
				(ISNULL(@Date5, '1900/01/01'))
		) AS d (MaxDate)
);
GO

select * from fn_GetMaxDate('2021-12-31','2001-09-11',NULL,NULL,NULL)
GO

DROP FUNCTION fn_GetMaxDate
GO
