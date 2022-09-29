create view babel_2805_vu_v1 as
SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8), (9, 10) ) AS MyTable(a, b);
go

CREATE FUNCTION babel_2805_vu_f1
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
