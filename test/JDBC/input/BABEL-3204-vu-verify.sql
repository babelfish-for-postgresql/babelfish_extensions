USE db_babel_3204;
go

SELECT babel_3204_complex_func('abc def', ' ');
go

SELECT babel_3204_text();
go

SELECT babel_3204_ntext();
go

SELECT babel_3204_image();
go

DROP FUNCTION babel_3204_complex_func;
go

DROP FUNCTION babel_3204_text;
go

DROP FUNCTION babel_3204_ntext;
go

DROP FUNCTION babel_3204_image;
go

USE master;
go

DROP DATABASE db_babel_3204;
go