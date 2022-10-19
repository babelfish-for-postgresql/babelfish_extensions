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

create table babel_2805_vu_t1 (a int, b int)
create table babel_2805_vu_t2 (c int, d int)
insert into babel_2805_vu_t1 values (1, 1),(2, 2)
insert into babel_2805_vu_t2 values (3, 3),(4, 4)
go

create view babel_2805_vu_v2 as
select * from babel_2805_vu_t1 cross join (values (3, 3),(4,4)) babel_2805_vu_t2(c1, c2);
go

create procedure babel_2805_vu_p1 as
select * from babel_2805_vu_t1 cross join babel_2805_vu_t2;
go

create procedure babel_2805_vu_p2 as
select * from babel_2805_vu_t1 cross join (select * from babel_2805_vu_t2) t2(c1, c2);
go
