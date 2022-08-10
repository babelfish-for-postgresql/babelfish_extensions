USE MASTER;
GO

CREATE TABLE dbo.babel_1444_vu_prepare_t1
(id INT IDENTITY(100, 1) NOT NULL,
 description VARCHAR(30) NOT NULL,
 usr VARCHAR(30) NOT NULL DEFAULT USER,
 cur_usr VARCHAR(30) NOT NULL DEFAULT CURRENT_USER);
GO

INSERT INTO dbo.babel_1444_vu_prepare_t1 (description) VALUES ('Orange');
INSERT INTO dbo.babel_1444_vu_prepare_t1 (description) VALUES ('Blue');
INSERT INTO dbo.babel_1444_vu_prepare_t1 (description, usr) VALUES ('Green', 'Bob');
INSERT INTO dbo.babel_1444_vu_prepare_t1 (description, cur_usr) VALUES ('Purple', 'Alice');
INSERT INTO dbo.babel_1444_vu_prepare_t1 (description, usr, cur_usr) VALUES ('Red', 'Mike', 'Dave');
GO