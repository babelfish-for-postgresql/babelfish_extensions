CREATE TABLE BABEL_3249_VU_TAB(C1 INT, C2 VARCHAR(100))
GO

INSERT INTO BABEL_3249_VU_TAB VALUES(1, 'abc')
INSERT INTO BABEL_3249_VU_TAB VALUES(2, 'ghl')
INSERT INTO BABEL_3249_VU_TAB VALUES(3, 'xyz')
GO

CREATE TRIGGER BABEL_3249_VU_TRIG_FOR
ON BABEL_3249_VU_TAB
FOR INSERT, UPDATE
AS
	SELECT * FROM BABEL_3249_VU_TAB;
GO

CREATE TRIGGER BABEL_3249_VU_TRIG_AFTER
ON BABEL_3249_VU_TAB
AFTER DELETE
AS
	INSERT INTO BABEL_3249_VU_TAB VALUES(10, 'fjf');
GO

