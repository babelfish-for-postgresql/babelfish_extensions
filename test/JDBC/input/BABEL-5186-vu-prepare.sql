CREATE PROCEDURE babel_5186_try_catch_relation_err1
AS
    SELECT * FROM non_existent_table;
GO

CREATE PROCEDURE babel_5186_try_catch_relation_err2
AS
BEGIN
    BEGIN TRAN
        SELECT * FROM non_existent_table;
    COMMIT TRAN
END
GO

CREATE TABLE babel_5186_try_catch_table (a INT)
GO

CREATE PROCEDURE babel_5186_try_catch_column_err1
AS
    SELECT non_existent_column FROM babel_5186_try_catch_table;
GO

CREATE PROCEDURE babel_5186_try_catch_column_err2
AS
BEGIN
    BEGIN TRAN
        SELECT non_existent_column FROM babel_5186_try_catch_table;
    COMMIT TRAN
END
GO

CREATE TABLE babel_5186_table_errTable (a int)
GO

-- Simple procedure with transaction
CREATE PROCEDURE babel_5186_errProc1_1
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (411);
BEGIN TRAN;
INSERT INTO babel_5186_table_errTable VALUES (412);
SELECT * FROM non_existent_table;
COMMIT TRAN;
INSERT INTO babel_5186_table_errTable VALUES (413);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc1_2
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (421);
BEGIN TRAN;
INSERT INTO babel_5186_table_errTable VALUES (422);
EXEC('SELECT * FROM non_existent_table;');
COMMIT TRAN;
INSERT INTO babel_5186_table_errTable VALUES (423);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc1_3
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (431);
BEGIN TRAN;
INSERT INTO babel_5186_table_errTable VALUES (432);
SELECT non_existent_column FROM babel_5186_try_catch_table;
COMMIT TRAN;
INSERT INTO babel_5186_table_errTable VALUES (433);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc1_4
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (441);
BEGIN TRAN;
INSERT INTO babel_5186_table_errTable VALUES (442);
EXEC('SELECT non_existent_column FROM babel_5186_try_catch_table;');
COMMIT TRAN;
INSERT INTO babel_5186_table_errTable VALUES (443);
COMMIT TRAN;
GO

-- Nested procedure
CREATE PROCEDURE babel_5186_errProc2_1
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (511);
INSERT INTO babel_5186_table_errTable VALUES (512);
SELECT * FROM non_existent_table;
INSERT INTO babel_5186_table_errTable VALUES (513);
GO

CREATE PROCEDURE babel_5186_errProc2_11
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (514);
EXEC babel_5186_errProc2_1;
INSERT INTO babel_5186_table_errTable VALUES (515);
GO

CREATE PROCEDURE babel_5186_errProc2_2
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (521);
INSERT INTO babel_5186_table_errTable VALUES (522);
EXEC('SELECT * FROM non_existent_table;');
INSERT INTO babel_5186_table_errTable VALUES (523);
GO

CREATE PROCEDURE babel_5186_errProc2_21
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (524);
EXEC babel_5186_errProc2_2;
INSERT INTO babel_5186_table_errTable VALUES (525);
GO

CREATE PROCEDURE babel_5186_errProc2_3
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (531);
INSERT INTO babel_5186_table_errTable VALUES (532);
SELECT non_existent_column FROM babel_5186_try_catch_table;
INSERT INTO babel_5186_table_errTable VALUES (533);
GO

CREATE PROCEDURE babel_5186_errProc2_31
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (534);
EXEC babel_5186_errProc2_3;
INSERT INTO babel_5186_table_errTable VALUES (535);
GO

CREATE PROCEDURE babel_5186_errProc2_4
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (541);
INSERT INTO babel_5186_table_errTable VALUES (542);
EXEC('SELECT non_existent_column FROM babel_5186_try_catch_table;');
INSERT INTO babel_5186_table_errTable VALUES (543);
GO

CREATE PROCEDURE babel_5186_errProc2_41
AS
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (544);
EXEC babel_5186_errProc2_4;
INSERT INTO babel_5186_table_errTable VALUES (545);
GO

-- Nest procedure with transaction
CREATE PROCEDURE babel_5186_errProc3_1
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (611);
INSERT INTO babel_5186_table_errTable VALUES (612);
SELECT * FROM non_existent_table;
INSERT INTO babel_5186_table_errTable VALUES (613);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_11
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (614);
EXEC babel_5186_errProc3_1;
INSERT INTO babel_5186_table_errTable VALUES (615);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_2
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (621);
INSERT INTO babel_5186_table_errTable VALUES (622);
EXEC('SELECT * FROM non_existent_table;');
INSERT INTO babel_5186_table_errTable VALUES (623);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_21
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (624);
EXEC babel_5186_errProc3_2;
INSERT INTO babel_5186_table_errTable VALUES (625);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_3
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (631);
INSERT INTO babel_5186_table_errTable VALUES (632);
SELECT non_existent_column FROM babel_5186_try_catch_table;
INSERT INTO babel_5186_table_errTable VALUES (633);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_31
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (634);
EXEC babel_5186_errProc3_3;
INSERT INTO babel_5186_table_errTable VALUES (635);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_4
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (641);
INSERT INTO babel_5186_table_errTable VALUES (642);
EXEC('SELECT non_existent_column FROM babel_5186_try_catch_table;');
INSERT INTO babel_5186_table_errTable VALUES (643);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_errProc3_41
AS
BEGIN TRAN
SET XACT_ABORT ON;
INSERT INTO babel_5186_table_errTable VALUES (644);
EXEC babel_5186_errProc3_4;
INSERT INTO babel_5186_table_errTable VALUES (645);
COMMIT TRAN;
GO


-- XACT_ABORT OFF
CREATE TABLE babel_5186_1_try_catch_table (a INT)
GO

CREATE TABLE babel_5186_1_table_errTable (a int)
GO
-- Simple procedure with transaction
CREATE PROCEDURE babel_5186_1_errProc1_1
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (411);
BEGIN TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (412);
SELECT * FROM non_existent_table;
COMMIT TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (413);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc1_2
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (421);
BEGIN TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (422);
EXEC('SELECT * FROM non_existent_table;');
COMMIT TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (423);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc1_3
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (431);
BEGIN TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (432);
SELECT non_existent_column FROM babel_5186_1_try_catch_table;
COMMIT TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (433);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc1_4
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (441);
BEGIN TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (442);
EXEC('SELECT non_existent_column FROM babel_5186_1_try_catch_table;');
COMMIT TRAN;
INSERT INTO babel_5186_1_table_errTable VALUES (443);
COMMIT TRAN;
GO

-- Nested procedure
CREATE PROCEDURE babel_5186_1_errProc2_1
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (511);
INSERT INTO babel_5186_1_table_errTable VALUES (512);
SELECT * FROM non_existent_table;
INSERT INTO babel_5186_1_table_errTable VALUES (513);
GO

CREATE PROCEDURE babel_5186_1_errProc2_11
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (514);
EXEC babel_5186_1_errProc2_1;
INSERT INTO babel_5186_1_table_errTable VALUES (515);
GO

CREATE PROCEDURE babel_5186_1_errProc2_2
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (521);
INSERT INTO babel_5186_1_table_errTable VALUES (522);
EXEC('SELECT * FROM non_existent_table;');
INSERT INTO babel_5186_1_table_errTable VALUES (523);
GO

CREATE PROCEDURE babel_5186_1_errProc2_21
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (524);
EXEC babel_5186_1_errProc2_2;
INSERT INTO babel_5186_1_table_errTable VALUES (525);
GO

CREATE PROCEDURE babel_5186_1_errProc2_3
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (531);
INSERT INTO babel_5186_1_table_errTable VALUES (532);
SELECT non_existent_column FROM babel_5186_1_try_catch_table;
INSERT INTO babel_5186_1_table_errTable VALUES (533);
GO

CREATE PROCEDURE babel_5186_1_errProc2_31
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (534);
EXEC babel_5186_1_errProc2_3;
INSERT INTO babel_5186_1_table_errTable VALUES (535);
GO

CREATE PROCEDURE babel_5186_1_errProc2_4
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (541);
INSERT INTO babel_5186_1_table_errTable VALUES (542);
EXEC('SELECT non_existent_column FROM babel_5186_1_try_catch_table;');
INSERT INTO babel_5186_1_table_errTable VALUES (543);
GO

CREATE PROCEDURE babel_5186_1_errProc2_41
AS
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (544);
EXEC babel_5186_1_errProc2_4;
INSERT INTO babel_5186_1_table_errTable VALUES (545);
GO

-- Nest procedure with transaction
CREATE PROCEDURE babel_5186_1_errProc3_1
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (611);
INSERT INTO babel_5186_1_table_errTable VALUES (612);
SELECT * FROM non_existent_table;
INSERT INTO babel_5186_1_table_errTable VALUES (613);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_11
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (614);
EXEC babel_5186_1_errProc3_1;
INSERT INTO babel_5186_1_table_errTable VALUES (615);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_2
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (621);
INSERT INTO babel_5186_1_table_errTable VALUES (622);
EXEC('SELECT * FROM non_existent_table;');
INSERT INTO babel_5186_1_table_errTable VALUES (623);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_21
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (624);
EXEC babel_5186_1_errProc3_2;
INSERT INTO babel_5186_1_table_errTable VALUES (625);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_3
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (631);
INSERT INTO babel_5186_1_table_errTable VALUES (632);
SELECT non_existent_column FROM babel_5186_1_try_catch_table;
INSERT INTO babel_5186_1_table_errTable VALUES (633);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_31
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (634);
EXEC babel_5186_1_errProc3_3;
INSERT INTO babel_5186_1_table_errTable VALUES (635);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_4
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (641);
INSERT INTO babel_5186_1_table_errTable VALUES (642);
EXEC('SELECT non_existent_column FROM babel_5186_1_try_catch_table;');
INSERT INTO babel_5186_1_table_errTable VALUES (643);
COMMIT TRAN;
GO

CREATE PROCEDURE babel_5186_1_errProc3_41
AS
BEGIN TRAN
SET XACT_ABORT OFF;
INSERT INTO babel_5186_1_table_errTable VALUES (644);
EXEC babel_5186_1_errProc3_4;
INSERT INTO babel_5186_1_table_errTable VALUES (645);
COMMIT TRAN;
GO
