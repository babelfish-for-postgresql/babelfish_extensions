-- 14.7 (aka extension version 2.4.0) has a major change to how FOR JSON
-- has been implemented, which slightly changes the behavior around some old error
-- messages as well, so we need to move those tests to a new test file that separately
-- exercises them outside of the pre-14.6 upgrade tests.

CREATE TABLE forjson_subquery_vu_t_countries (
[Id] INT,
[Age] INT,
[Country] VARCHAR(25))
GO

INSERT INTO forjson_subquery_vu_t_countries values
(1,25, 'India'),
(2,40, 'USA'),
(3,30, 'India'),
(4,20, NULL),
(5,10, 'USA')
GO

create table forjson_subquery_vu_t1 (x int)
insert into forjson_subquery_vu_t1 values (1)
go

-- FOR JSON AUTO clause not supported
CREATE VIEW forjson_subquery_vu_v_auto AS
SELECT (
	SELECT Id,
		   State
	FROM forjson_subquery_vu_t1
	FOR JSON AUTO
) c1
GO

-- Alias/colname not present
CREATE VIEW forjson_subquery_vu_v_no_alias AS
SELECT (
	SELECT 2
	FOR JSON PATH
) c1
GO

CREATE VIEW forjson_subquery_vu_v_with AS
WITH forjson_subquery_vu_with1(avg_age) AS (
	SELECT avg(Age)
	FROM forjson_subquery_vu_t_countries
)
SELECT (
	SELECT Id, Age, Country
	FROM forjson_subquery_vu_t_countries, forjson_subquery_vu_with1
	WHERE Age >= forjson_subquery_vu_with1.avg_age
	FOR JSON PATH
) C1
GO

CREATE VIEW forjson_subquery_vu_v_with_order_by AS
WITH forjson_subquery_vu_with2(avg_age) AS (
	SELECT avg(Age)
	FROM forjson_subquery_vu_t_countries
)
SELECT (
	SELECT Id, Age, Country 
	FROM forjson_subquery_vu_t_countries, forjson_subquery_vu_with2
	WHERE Age >= forjson_subquery_vu_with2.avg_age
	ORDER BY Country
	FOR JSON PATH
) c1
GO

-- Binary strings
CREATE TABLE forjson_subquery_vu_t_binary_strings(abinary binary, avarbinary varbinary(10))
GO
INSERT forjson_subquery_vu_t_binary_strings VALUES (123456,0x0a0b0c0d0e)
GO

-- Rowversion and timestamp
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
GO

CREATE TABLE forjson_subquery_vu_t_rowversion (myKey int, myValue int,RV rowversion);
GO
INSERT INTO forjson_subquery_vu_t_rowversion (myKey, myValue) VALUES (1, 0);
GO

CREATE TABLE forjson_subquery_vu_t_timestamp (myKey int, myValue int, timestamp);
GO
INSERT INTO forjson_subquery_vu_t_timestamp (myKey, myValue) VALUES (1, 0);
GO

-- Binary strings
CREATE VIEW forjson_subquery_vu_v_binary_strings AS
SELECT
(
    SELECT abinary 
    FROM forjson_subquery_vu_t_binary_strings
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_subquery_vu_v_varbinary_strings AS
SELECT
(
    SELECT avarbinary
    FROM forjson_subquery_vu_t_binary_strings
    FOR JSON PATH
) as c1;
GO

-- Rowversion and timestamp
CREATE VIEW forjson_subquery_vu_v_rowversion AS
SELECT
(
    SELECT *
    FROM forjson_subquery_vu_t_rowversion
    FOR JSON PATH
) as c1;
GO

CREATE VIEW forjson_subquery_vu_v_timestamp AS
SELECT
(
    SELECT *
    FROM forjson_subquery_vu_t_timestamp
    FOR JSON PATH
) as c1;
GO

-- BABEL-3569/BABEL-3690 return 0 rows for empty rowset
CREATE PROCEDURE forjson_subquery_vu_p_empty AS
SELECT * FROM forjson_subquery_vu_t_countries
	WHERE 1 = 0
	FOR JSON PATH
GO

-- exercise tsql_select_for_json_result internal function
CREATE VIEW forjson_subquery_vu_v_internal AS
SELECT * FROM tsql_select_for_json_result('abcd')
GO
