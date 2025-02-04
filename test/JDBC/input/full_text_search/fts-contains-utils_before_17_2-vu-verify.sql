SELECT * FROM fts_rewrite_prepare_v1;
GO

EXEC fts_rewrite_prepare_p1;
GO

SELECT fts_rewrite_prepare_f1();
GO

SELECT * FROM replace_special_chars_fts_prepare_v1;
GO

EXEC replace_special_chars_fts_prepare_p1;
GO

SELECT replace_special_chars_fts_prepare_f1();
GO

select sys.replace_special_chars_fts('"one @ @ @ @ two"');
go

select sys.babelfish_fts_rewrite('"one @ @ @ @ two"');
go

select sys.replace_special_chars_fts('"one @ two"');
go

select sys.replace_special_chars_fts('"one   @ two    ^ three"');
go

select sys.replace_special_chars_fts('"one:"');
go

select sys.replace_special_chars_fts('Arts '' grand-opening in 1987');
go

select sys.babelfish_fts_rewrite('"one   @ two    ^ three"');
go

select sys.babelfish_fts_rewrite('"one @ two"');
go

select sys.babelfish_fts_rewrite(':one');
select sys.babelfish_fts_rewrite('one:');
select sys.babelfish_fts_rewrite('one:  ');
select sys.babelfish_fts_rewrite('  :one');
select sys.babelfish_fts_rewrite('"one    :"');
select sys.babelfish_fts_rewrite('"one    :  "');
select sys.babelfish_fts_rewrite('":    one"');
select sys.babelfish_fts_rewrite('"    :     one"');
select sys.babelfish_fts_rewrite('"much of the"');
go

select sys.replace_special_chars_fts('one`two');
go