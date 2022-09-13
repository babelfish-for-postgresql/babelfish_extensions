--DELETE on correlation name 
CREATE TABLE BABEL_3380_vu_prepare_temp1 (id int)
CREATE TABLE BABEL_3380_vu_prepare_temp2 (id int)
INSERT INTO BABEL_3380_vu_prepare_temp1 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp2 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp1 VALUES(10)
DELETE t1
FROM BABEL_3380_vu_prepare_temp1 t1
INNER JOIN BABEL_3380_vu_prepare_temp2 t2
ON t1.id = t2.id
GO

--UPDATE on correlation name 
CREATE TABLE BABEL_3380_vu_prepare_temp3 (id int)
CREATE TABLE BABEL_3380_vu_prepare_temp4 (id int)
INSERT INTO BABEL_3380_vu_prepare_temp3 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp4 VALUES(1)
UPDATE t3
SET id = 50
FROM BABEL_3380_vu_prepare_temp3 t3
INNER JOIN BABEL_3380_vu_prepare_temp4 t4
ON t3.id = t4.id
GO

--DELETE on correlation name
CREATE TABLE BABEL_3380_vu_prepare_temp5 (id int)
CREATE TABLE BABEL_3380_vu_prepare_temp6 (id int)
INSERT INTO BABEL_3380_vu_prepare_temp5 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp6 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp6 VALUES(10)
DELETE t6
FROM BABEL_3380_vu_prepare_temp6 t6
INNER JOIN BABEL_3380_vu_prepare_temp5 t5
ON t5.id = t6.id
GO

--UPDATE on correlation name
CREATE TABLE BABEL_3380_vu_prepare_temp7 (id int)
CREATE TABLE BABEL_3380_vu_prepare_temp8 (id int)
INSERT INTO BABEL_3380_vu_prepare_temp7 VALUES(1)
INSERT INTO BABEL_3380_vu_prepare_temp8 VALUES(1)
UPDATE t8
SET id = 50
FROM BABEL_3380_vu_prepare_temp8 t8
INNER JOIN BABEL_3380_vu_prepare_temp7 t7
ON t7.id = t8.id
GO
