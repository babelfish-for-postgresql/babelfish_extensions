create view babel_2805_vu_v1 as
SELECT a, b FROM (VALUES (1, 2), (3, 4), (5, 6), (7, 8), (9, 10) ) AS MyTable(a, b);
go

create table babel_2805_vu_t1 (col1 nvarchar(20), col2 nvarchar(20))
go

insert into babel_2805_vu_t1 values ('name', '42')
go

create view babel_2805_vu_v2 as
select t.* from babel_2805_vu_t1
CROSS APPLY
(
    VALUES
        (1, 'col1', col1),
        (2, 'col2', col2)
) t(id, [name], [value]);
go

CREATE TABLE babel_2805_vu_t2(  
    SalesReasonID int IDENTITY(1,1) NOT NULL,  
    Name varchar(max) NULL ,  
    ReasonType varchar(max) NOT NULL DEFAULT 'Not Applicable' );  
GO

INSERT INTO babel_2805_vu_t2   
VALUES ('Recommendation','Other'), ('Advertisement', DEFAULT), (NULL, 'Promotion');
go

create view babel_2805_vu_v3 as
SELECT * FROM babel_2805_vu_t2;  
GO

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

create table babel_2805_vu_t3 (a int, b int)
create table babel_2805_vu_t4 (c int, d int)
insert into babel_2805_vu_t3 values (1, 1),(2, 2)
insert into babel_2805_vu_t4 values (3, 3),(4, 4)
go

create view babel_2805_vu_v4 as
select * from babel_2805_vu_t3 cross join (values (3, 3),(4,4)) babel_2805_vu_t4(c1, c2);
go

create procedure babel_2805_vu_p1 as
select * from babel_2805_vu_t3 cross join babel_2805_vu_t4;
go

create procedure babel_2805_vu_p2 as
select * from babel_2805_vu_t3 cross join (select * from babel_2805_vu_t4) t2(c1, c2);
go
