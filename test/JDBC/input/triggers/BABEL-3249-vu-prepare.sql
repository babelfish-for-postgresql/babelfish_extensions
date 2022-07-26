CREATE TABLE babel_3249_vu_prepare_TAB(C1 INT, C2 VARCHAR(100))
GO

INSERT INTO babel_3249_vu_prepare_TAB VALUES(1, 'abc')
INSERT INTO babel_3249_vu_prepare_TAB VALUES(2, 'ghl')
INSERT INTO babel_3249_vu_prepare_TAB VALUES(3, 'xyz')
GO

CREATE TRIGGER babel_3249_vu_prepare_TRIG_FOR
ON babel_3249_vu_prepare_TAB
FOR INSERT, UPDATE
AS
	SELECT * FROM babel_3249_vu_prepare_TAB;
GO

CREATE TRIGGER babel_3249_vu_prepare_TRIG_AFTER
ON babel_3249_vu_prepare_TAB
AFTER DELETE
AS
	INSERT INTO babel_3249_vu_prepare_TAB VALUES(10, 'fjf');
GO

