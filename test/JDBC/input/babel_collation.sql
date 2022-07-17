create table testing_collation (col varchar(20));
go
insert into testing_collation values ('JONES');
insert into testing_collation values ('jones');
insert into testing_collation values ('Jones');
insert into testing_collation values ('JoNes');
insert into testing_collation values ('JoNés');
go
select * from testing_collation where col collate SQL_Latin1_General_CP1_CS_AS = 'JoNes';
go

select * from testing_collation where col collate SQL_Latin1_General_CP1_CI_AS = 'JoNes';
go

select * from testing_collation where col collate SQL_Latin1_General_CP1_CI_AI = 'JoNes';
go

-- all the currently supported TSQL collations
SELECT * from fn_helpcollations() order by name;
go

select count(*) from fn_helpcollations();
go

-- BABEL-1697 Collation and Codepage information for DMS
SELECT CAST( COLLATIONPROPERTY(Name, 'CodePage') AS INT) FROM fn_helpcollations() where Name = DATABASEPROPERTYEX('master', 'Collation');
go

SELECT CAST( COLLATIONPROPERTY(Name, 'lcid') AS INT) FROM fn_helpcollations() where Name = DATABASEPROPERTYEX('master', 'Collation');
go

SELECT CASE WHEN 'a' = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END; -- expect case-insensitive
go

DECLARE @str varchar(64)
SELECT @str = 'a';
SELECT CASE WHEN @str = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END; -- expect case-insensitive
go

SELECT position = PATINDEX('%t_S%', 'Test String'); -- expect 1
go

SELECT position = PATINDEX('%t S%', 'Test String'); -- expect 4
go

SELECT position = PATINDEX('%t_S%', 'Test String' COLLATE bbf_unicode_general_cs_as); -- expect 4
go

SELECT position = PATINDEX('%[^ 0-9A-Za-z]%', 'Please ensure the door is locked!'); -- expect 33
go

DECLARE @document VARCHAR(64);
SELECT @document = 'Reflectors are vital safety' + ' components of your bicycle.';
SELECT CHARINDEX('Vital', @document, 5); -- expect 16 (case-insensitive)
go

SELECT CHARINDEX('sql', 'SQL Server CHARINDEX') position; -- expect 1
go

SELECT CHARINDEX('SERVER', 'SQL Server CHARINDEX') position; -- expect 5
go

SELECT 
    CHARINDEX(
        'SERVER', 
        'SQL Server CHARINDEX SERVER' 
        COLLATE latin1_general_bin2
    ) position; -- expect 22 - case-sensitive search
go

SELECT 
    CHARINDEX('is','This is a my sister',5) start_at_fifth, -- expect 6
    CHARINDEX('is','This is a my sister',10) start_at_tenth; -- expect 15
go

DECLARE @haystack VARCHAR(100);  
SELECT @haystack = 'This is a haystack';  
SELECT CHARINDEX('', @haystack); -- empty string - expect 1
go

DECLARE @haystack VARCHAR(100);  
SELECT @haystack = 'This is a haystack';  
SELECT CHARINDEX(NULL, @haystack); -- NULL string - expect NULL
go

SELECT value FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ');
go

SELECT value FROM STRING_SPLIT('a,b,c,d', ' ');
go

SELECT value FROM STRING_SPLIT('123abc456', 'abc'); -- expect 'invalid separator'
go

DECLARE @tags NVARCHAR(400) = 'clothing,road,,touring,bike'  
  
SELECT value  
FROM STRING_SPLIT(@tags, ',')  
WHERE RTRIM(value) <> '';

SELECT REPLACE('foo bar FooBar', 'foo', 'B A R');
SELECT REPLACE('empty pattern', '', 'STR');
SELECT REPLACE('null pattern', NULL, 'STR');
SELECT REPLACE('null replacement', 'foo', NULL);
SELECT REPLACE('foo bar FooBar' COLLATE SQL_Latin1_General_CP1_CS_AS, 'foo', 'bar'); -- 2nd Foo is not replaced
SELECT REPLACE('nothing to do', 'none', 'should not see this');


-- clean up
drop table testing_collation;
go
