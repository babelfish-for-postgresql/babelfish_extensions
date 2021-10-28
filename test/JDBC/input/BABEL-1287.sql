-- implicit casting: uniqueidentifier -> string

create table babel_1287_t1 (a uniqueidentifier);
GO
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x00));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x1));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x01));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x123));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x00010203040506070809));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x000102030405060708090a0b0c0d0e0f));
insert into babel_1287_t1 values (convert(uniqueidentifier, 0x000102030405060708090a0b0c0d0e0f1011121314));
GO

CREATE FUNCTION babel_1287_f_char(@v char(40))
RETURNS varchar(40) AS
BEGIN
  RETURN @v;
END
GO

CREATE FUNCTION babel_1287_f_varchar(@v varchar(40))
RETURNS varchar(40) AS
BEGIN
  RETURN @v;
END
GO

CREATE FUNCTION babel_1287_f_text(@v text)
RETURNS text AS
BEGIN
  RETURN @v;
END
GO

SELECT babel_1287_f_char(a) char_result, babel_1287_f_varchar(a) varchar_result, babel_1287_f_text(a) text_result FROM babel_1287_t1;
GO

-- implicit casting: string -> uniqueidentifier
create table babel_1287_tmp(a varchar(50));
insert into babel_1287_tmp values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');
insert into babel_1287_tmp values ('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong');
insert into babel_1287_tmp values ('{6F9619FF-8B86-D011-B42D-00C04FC964FF}');
GO
create table babel_1287_t2 (a char(50), b varchar(50), c text);
insert into babel_1287_t2 select a, a, a from babel_1287_tmp;
truncate table babel_1287_tmp;
GO

insert into babel_1287_tmp values ('wrong6F9619FF-8B86-D011-B42D-00C04FC964FF');
create table babel_1287_t2_invalid1 (a char(50), b varchar(50), c text);
insert into babel_1287_t2_invalid1 select a, a, a from babel_1287_tmp;
truncate table babel_1287_tmp;
GO

insert into babel_1287_tmp values ('6F9619FF-8B86-D011-B42D-WRONGFC964FF');
create table babel_1287_t2_invalid2 (a char(50), b varchar(50), c text);
insert into babel_1287_t2_invalid2 select a, a, a from babel_1287_tmp;
truncate table babel_1287_tmp;
GO

CREATE FUNCTION babel_1287_f_ui(@v uniqueidentifier)
RETURNS uniqueidentifier AS
BEGIN
  RETURN @v;
END
GO

SELECT babel_1287_f_ui(a) char_in, babel_1287_f_ui(b) varchar_in, babel_1287_f_ui(c) text_in from babel_1287_t2;
GO

-- wrong input
SELECT babel_1287_f_ui(a) char_in from babel_1287_t2_invalid1;
GO
SELECT babel_1287_f_ui(b) varchar_in from babel_1287_t2_invalid1;
GO
SELECT babel_1287_f_ui(c) text_in from babel_1287_t2_invalid1;
GO

-- wrong input
SELECT babel_1287_f_ui(a) char_in from babel_1287_t2_invalid2;
GO
SELECT babel_1287_f_ui(b) varchar_in from babel_1287_t2_invalid2;
GO
SELECT babel_1287_f_ui(c) text_in from babel_1287_t2_invalid2;
GO

DROP FUNCTION babel_1287_f_char;
DROP FUNCTION babel_1287_f_varchar;
DROP FUNCTION babel_1287_f_text;
DROP FUNCTION babel_1287_f_ui;
GO

DROP TABLE babel_1287_t1;
DROP TABLE babel_1287_t2;
DROP TABLE babel_1287_t2_invalid1;
DROP TABLE babel_1287_t2_invalid2;
DROP TABLE babel_1287_tmp;
GO
