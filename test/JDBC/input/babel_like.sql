-- parallel_query_expected
select relname from pg_class where relname like NULL;
GO
select relname from pg_class where relname like '';
GO
select relname from pg_class where relname like 'pg\[1:9\]class';
GO

select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
GO

select relname from pg_class where relname like NULL;
GO
select relname from pg_class where relname like '';
GO
select relname from pg_class where relname like 'pg\[1:9\]class';
GO


select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
GO

CREATE TABLE babel_like_t1(col1 varchar(11));
GO

INSERT INTO babel_like_t1 VALUES ('ab');
GO

SET BABELFISH_SHOWPLAN_ALL ON;
GO

SELECT * FROM babel_like_t1 WHERE col1 LIKE 'ab' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM babel_like_t1 WHERE col1 LIKE 'a%' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM babel_like_t1 WHERE col1 LIKE 'ab' COLLATE Latin1_General_CI_AS;
GO

SELECT * FROM babel_like_t1 WHERE col1 LIKE 'a%' COLLATE Latin1_General_CI_AS;
GO

SET BABELFISH_SHOWPLAN_ALL OFF;
GO

DROP TABLE babel_like_t1;
GO