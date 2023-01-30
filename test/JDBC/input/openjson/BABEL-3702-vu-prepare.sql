CREATE PROCEDURE BABEL_3702_vu_prepare_p6
AS
BEGIN
    DECLARE @json NVARCHAR(MAX) = N'{"obj":{"a":1}}'
    DECLARE @path NVARCHAR(MAX) = N'$.obj'
    SELECT * FROM OPENJSON(@json, @path) with (a nvarchar(20))
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p6_2
AS
BEGIN
    DECLARE @json NCHAR(4000) = N'{"obj":{"a":1}}'
    DECLARE @path NCHAR(4000) = N'$.obj'
    SELECT * FROM OPENJSON(@json, @path) with (a nchar(20))
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p6_3
AS
BEGIN
    DECLARE @json CHAR(50) = N'{"obj":{"a":1}}'
    DECLARE @path CHAR(50) = N'$.obj'
    SELECT * FROM OPENJSON(@json, @path) with (a char(20))
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p7 as (select * from openjson(N'{"a":"long string"}') with (a nvarchar(5)));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$' AS JSON)
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8_2
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name char(4000) '$')
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8_3
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name nchar(4000) '$')
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8_4
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name pg_catalog.char(4000) '$')
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8_5
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name sys.nvarchar(max) '$' AS JSON)
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p9 as (SELECT * FROM OPENJSON(N'{"a":1}') WITH (obj nvarchar(20) '$' AS JSON));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p10
AS
BEGIN
    DECLARE @json NVARCHAR(4000) = N'{ 
        "pets" : {
                "cats" : [
                { "id" : 1, "name" : "Fluffy", "sex" : "Female" },
                { "id" : 2, "name" : "Long Tail", "sex" : "Female" },
                { "id" : 3, "name" : "Scratch", "sex" : "Male" }
            ],
                "dogs" : [
                { "name" : "Fetch", "sex" : "Male" },
                { "name" : "Fluffy", "sex" : "Male" },
                { "name" : "Wag", "sex" : "Female" }
            ]
        }
    }';
    SELECT * FROM OPENJSON(@json, '$.pets.cats')
    WITH  (
            [Cat Id]    int             '$.id',  
            "Cat Name"  varchar(60)     '$.name', 
            [Sex]       varchar(6)      '$.sex', 
            [Cats]      nvarchar(max)   '$' AS JSON   
        )
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p11
AS
BEGIN
DECLARE @json_text NVARCHAR(MAX)
SET @json_text = N'
{
    "moon_landing": "1969-07-20T02:56:00+00:00",
    "seconds_in_a_day": "86400",
    "console_is_better_than_pc": true,
    "hundred_meter_world_record": "9.58"
}
'

SELECT
    random_facts.moon_landing
    ,random_facts.seconds_in_a_day / 3600 as hours_in_a_day
    ,random_facts.console_is_better_than_pc
    ,(100 / random_facts.hundred_meter_world_record) * 3.6 as hmwr_kph
FROM
    OPENJSON(@json_text)
        WITH (
            moon_landing DATETIME2
            ,seconds_in_a_day INT
            ,console_is_better_than_pc BIT
            ,hundred_meter_world_record FLOAT 
        ) as random_facts
END;
GO

create table fdefs (id int, fname nvarchar(20))
insert into fdefs values (1, 'alpha'),(2, 'bravo')
create table ftypes (id int, ftype nvarchar(20))
insert into ftypes values (1, 'type1'),(3, 'type3')
go

create procedure BABEL_3702_vu_prepare_p12 @body nvarchar(max) as
select
	fname
from
	fdefs d
	join ftypes t on d.id = t.id
	left join
		openjson(json_query(@body, '$.udfs'))
		with (
			jname nvarchar(40) '$.name',
			jvalue nvarchar(max) '$.value'
		) j
		on j.jname = d.fname
go

CREATE PROCEDURE BABEL_3702_vu_prepare_p13 AS (SELECT * FROM OPENJSON('["Cat","Dog","Bird"]'));
GO