INSERT INTO babel_3118_vu_prepare_t(c2) VALUES ('Joe'), ('Steve');
GO

SELECT * FROM babel_3118_vu_prepare_t;
GO

DELETE FROM babel_3118_vu_prepare_t WHERE c2 = 'Steve';
GO

SELECT  * FROM babel_3118_vu_prepare_t;
GO

