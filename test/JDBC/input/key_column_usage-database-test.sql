use master;
go

create table key_column_usage_db_test_tb1(redID INT PRIMARY KEY, greenID INT NOT NULL UNIQUE, blueID INT NOT NULL, UNIQUE(greenID,blueID));
go

create table key_column_usage_db_test_tb2( greenID char(10) PRIMARY KEY, redID INT NOT NULL, CONSTRAINT FK_RED FOREIGN KEY (redID) REFERENCES key_column_usage_db_test_tb1 (redID));
go

create database key_column_usage_db_test_db;
go

use key_column_usage_db_test_db;
go

create table key_column_usage_db_test_tb3(blueID INT PRIMARY KEY, greenID char(10));
go

create table key_column_usage_db_test_tb4(purpleID INT PRIMARY KEY, blueID INT NOT NULL, CONSTRAINT FK_GREEN FOREIGN KEY (blueID) REFERENCES key_column_usage_db_test_tb3(blueID));
go

use master;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_db_test_tb%' order by table_name,constraint_name,table_schema;
go

use key_column_usage_db_test_db;
go

select * from information_schema.key_column_usage where table_name like 'key_column_usage_db_test_tb%' order by table_name,constraint_name,table_schema;
go

drop table key_column_usage_db_test_tb4;
go

drop table key_column_usage_db_test_tb3;
go

use master;
go

drop table key_column_usage_db_test_tb2;
go

drop table key_column_usage_db_test_tb1;
go

drop database key_column_usage_db_test_db;
go
