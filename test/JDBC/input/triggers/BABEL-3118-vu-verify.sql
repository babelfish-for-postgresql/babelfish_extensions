INSERT INTO babel_3118_t(c2) VALUES ('Joe'), ('Steve');
GO

SELECT * FROM babel_3118_t;
GO

DELETE FROM babel_3118_t WHERE c2 = 'Steve';
GO

SELECT  * FROM babel_3118_t;
GO

