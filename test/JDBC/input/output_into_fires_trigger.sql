-- Below statements will fire an after trigger
-- INSERT non local table OUTPUT ... INTO local table 
-- UPDATE non local table OUTPUT ... INTO local table
-- DELETE non local table OUTPUT ... INTO local table

-- REPEAT THE ABOVE INSIDE
	-- PROCEDURE
	-- TRIGGER
	-- FUNCTION (functions should not be allowed to create for output to client or non local object)

-- SOME MORE CASES OF OUTPUT CLAUSE WHICH SHOULD NOT BE ALLOWED INSIDE PLTSQL FUNCTIONS
-- OUTPUT TO CLIENT & OUTPUT INTO NON LOCAL OBJECT



CREATE TABLE babel_4859_t (id INT)
GO


-- INSERT table OUTPUT ... INTO table variable
CREATE TRIGGER [dbo].[babel_4859_trigger_insert]
	ON [dbo].[babel_4859_t]
AFTER INSERT
AS
SET NOCOUNT ON
SELECT 1;
GO

DECLARE @babel_4859_tabvar TABLE (id INT);
INSERT INTO babel_4859_t OUTPUT INSERTED.id INTO @babel_4859_tabvar VALUES (4859), (9584), (2), (3)
GO

-- UPDATE table OUTPUT ... INTO table variable
CREATE TRIGGER [dbo].[babel_4859_trigger_update]
	ON [dbo].[babel_4859_t]
AFTER UPDATE
AS
SET NOCOUNT ON
SELECT 1;
GO

DECLARE @babel_4859_tabvar TABLE (id INT, id_old INT);
UPDATE babel_4859_t SET id = 77 OUTPUT INSERTED.id, DELETED.id INTO @babel_4859_tabvar
GO

-- DELETE table OUTPUT ... INTO table variable
CREATE TRIGGER [dbo].[babel_4859_trigger_delete]
	ON [dbo].[babel_4859_t]
AFTER delete
AS
SET NOCOUNT ON
SELECT 1;
GO

DECLARE @babel_4859_tabvar TABLE (id_old INT);
DELETE babel_4859_t OUTPUT DELETED.id INTO @babel_4859_tabvar
GO

-- INSERT table OUTPUT ... INTO table variable INSIDE PROCEDURE
CREATE PROCEDURE babel_4859_p
AS
DECLARE @babel_4859_tabvar TABLE (id INT);
INSERT INTO babel_4859_t OUTPUT INSERTED.id INTO @babel_4859_tabvar VALUES (4859), (9584), (2), (3)
GO

EXEC babel_4859_p
GO

DROP PROC babel_4859_p
GO

-- UPDATE table OUTPUT ... INTO table variable INSIDE PROCEDURE
CREATE PROCEDURE babel_4859_p
AS
DECLARE @babel_4859_tabvar TABLE (id INT, id_old INT);
UPDATE babel_4859_t SET id = 77 OUTPUT INSERTED.id, DELETED.id INTO @babel_4859_tabvar
GO

EXEC babel_4859_p
GO

DROP PROC babel_4859_p
GO

-- DELETE table OUTPUT ... INTO table variable INSIDE PROCEDURE
CREATE PROCEDURE babel_4859_p
AS
DECLARE @babel_4859_tabvar TABLE (id_old INT);
DELETE babel_4859_t OUTPUT DELETED.id INTO @babel_4859_tabvar
GO

EXEC babel_4859_p
GO

DROP PROC babel_4859_p
GO

CREATE TABLE babel_4859_t2 (id INT)
GO

-- INSERT table OUTPUT ... INTO table variable INSIDE TRIGGER which will in turn fire another trigger
CREATE TRIGGER [dbo].[babel_4859_t2_trigger_insert]
	ON [dbo].[babel_4859_t2]
AFTER INSERT
AS
SET NOCOUNT ON
DECLARE @babel_4859_tabvar TABLE (id INT);
INSERT INTO babel_4859_t OUTPUT INSERTED.id INTO @babel_4859_tabvar VALUES (4859), (9584), (2), (3)
SELECT * FROM @babel_4859_tabvar
GO

INSERT INTO babel_4859_t2 VALUES (1)
GO

DROP TRIGGER [dbo].[babel_4859_t2_trigger_insert]
GO

-- UPDATE table OUTPUT ... INTO table variable INSIDE TRIGGER which will in turn fire another trigger
CREATE TRIGGER [dbo].[babel_4859_t2_trigger_insert]
	ON [dbo].[babel_4859_t2]
AFTER INSERT
AS
SET NOCOUNT ON
DECLARE @babel_4859_tabvar TABLE (id INT, id_old INT);
UPDATE babel_4859_t SET id = 77 OUTPUT INSERTED.id, DELETED.id INTO @babel_4859_tabvar
SELECT * FROM @babel_4859_tabvar
GO

INSERT INTO babel_4859_t2 VALUES (1)
GO

DROP TRIGGER [dbo].[babel_4859_t2_trigger_insert]
GO

-- DELETE table OUTPUT ... INTO table variable INSIDE TRIGGER which will in turn fire another trigger
CREATE TRIGGER [dbo].[babel_4859_t2_trigger_insert]
	ON [dbo].[babel_4859_t2]
AFTER INSERT
AS
SET NOCOUNT ON
DECLARE @babel_4859_tabvar TABLE (id_old INT);
DELETE babel_4859_t OUTPUT DELETED.id INTO @babel_4859_tabvar
SELECT * FROM @babel_4859_tabvar
GO

INSERT INTO babel_4859_t2 VALUES (1)
GO

DROP TRIGGER [dbo].[babel_4859_t2_trigger_insert]
GO


-- INSERT table OUTPUT ... INTO table variable INSIDE FUNCTION
-- Should fail because inserting into non local object
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	INSERT INTO babel_4859_t OUTPUT INSERTED.id INTO @babel_4859_tabvar VALUES (4859), (9584), (2), (3)
	RETURN 1
END
GO

-- UPDATE table OUTPUT ... INTO table variable INSIDE FUNCTION
-- Should fail because updating non local object
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT, id_old INT);
	UPDATE babel_4859_t SET id = 77 OUTPUT INSERTED.id, DELETED.id INTO @babel_4859_tabvar
	RETURN 1
END
GO

-- DELETE table OUTPUT ... INTO table variable INSIDE FUNCTION
-- Should fail because deleting from non local object
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id_old INT);
	DELETE babel_4859_t OUTPUT DELETED.id INTO @babel_4859_tabvar
	RETURN 1
END
GO



-- OUTPUT TO CLIENT SHOUD BE BLOCKED INSIDE FUNCTIONS
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	INSERT INTO @babel_4859_tabvar OUTPUT INSERTED.id VALUES (4859), (9584), (2), (3)
	RETURN 1
END
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	UPDATE @babel_4859_tabvar SET id = 77 OUTPUT INSERTED.id, DELETED.id
	RETURN 1
END
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	DELETE @babel_4859_tabvar OUTPUT DELETED.id
	RETURN 1
END
GO


-- OUTPUT INTO NON LOCAL OBJECTS SHOULD NOT BE ALLOWED INSIDE FUNCTIONS
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	INSERT INTO @babel_4859_tabvar OUTPUT INSERTED.id INTO babel_4859_t2 VALUES (4859), (9584), (2), (3)
	RETURN 1
END
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	UPDATE @babel_4859_tabvar SET id = 77 OUTPUT INSERTED.id INTO babel_4859_t2
	RETURN 1
END
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	DELETE @babel_4859_tabvar OUTPUT DELETED.id INTO babel_4859_t2
	RETURN 1
END
GO

-- OUTPUT INTO LOCAL OBJECTS SHOULD BE ALLOWED INSIDE FUNCTIONS
CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	DECLARE @babel_4859_tabvar_2 TABLE (id INT);
	INSERT INTO @babel_4859_tabvar OUTPUT INSERTED.id INTO @babel_4859_tabvar_2 VALUES (4859), (9584), (2), (3)
	RETURN 1
END
GO
DROP FUNCTION babel_4859_f1
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	DECLARE @babel_4859_tabvar_2 TABLE (id INT);
	UPDATE @babel_4859_tabvar SET id = 77 OUTPUT INSERTED.id INTO @babel_4859_tabvar_2
	RETURN 1
END
GO
DROP FUNCTION babel_4859_f1
GO

CREATE FUNCTION babel_4859_f1()
RETURNS INT
AS
BEGIN
	DECLARE @babel_4859_tabvar TABLE (id INT);
	DECLARE @babel_4859_tabvar_2 TABLE (id INT);
	DELETE @babel_4859_tabvar OUTPUT DELETED.id INTO @babel_4859_tabvar_2
	RETURN 1
END
GO
DROP FUNCTION babel_4859_f1
GO

DROP TABLE babel_4859_t, babel_4859_t2
GO