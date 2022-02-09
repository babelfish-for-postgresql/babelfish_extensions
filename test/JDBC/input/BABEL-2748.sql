use master;
go

exec sp_cursor
go

declare @cursor_handle int;
exec sp_cursor @cursor_handle;
go

declare @cursor_handle int;
exec sp_cursor @cursor_handle, 40
go

declare @cursor_handle int;
exec sp_cursor @cursor_handle, 40, 1
go

exec sp_cursorclose;
go

exec sp_cursorexecute;
go

declare @stmt_handle int;
exec sp_cursorexecute @stmt_handle;
go

exec sp_cursorfetch;
go

declare @cursor_handle int;
exec sp_cursorfetch @cursor_handle, 2, 0, 1, 'dummy';
go

exec sp_cursoropen;
go

declare @cursor_handle int;
exec sp_cursoropen @cursor_handle OUTPUT;
go

exec sp_cursoroption;
go

declare @cursor_handle int;
exec sp_cursoroption @cursor_handle;
go

declare @cursor_handle int;
exec sp_cursoroption @cursor_handle, 1;
go

declare @cursor_handle int;
exec sp_cursoroption @cursor_handle, 1, 2, 'dummy';
go

exec sp_cursorprepare;
go

declare @stmt_handle int;
exec sp_cursorprepare @stmt_handle OUTPUT;
go

declare @stmt_handle int;
exec sp_cursorprepare @stmt_handle OUTPUT, N'';
go

declare @stmt_handle int;
exec sp_cursorprepare @stmt_handle OUTPUT, N'', 'select i, d, c, u from babel_cursor_t1';
go

declare @stmt_handle int;
exec sp_cursorprepare @stmt_handle OUTPUT, N'', 'select i, d, c, u from babel_cursor_t1', 0, 2, 1, 'dummy';
go

exec sp_cursorprepexec;
go

declare @stmt_handle int;
exec sp_cursorprepexec @stmt_handle OUTPUT;
go

declare @stmt_handle int;
declare @cursor_handle int;
exec sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT;
go

declare @stmt_handle int;
declare @cursor_handle int;
exec sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT, N'';
go

declare @stmt_handle int;
declare @cursor_handle int;
exec sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT, N'', 'select i+100 from babel_cursor_t1';
go

exec sp_cursorunprepare;
go

declare @stmt_handle int;
exec sp_cursorunprepare @stmt_handle, 'dummy';
go

exec sp_execute;
go

exec sp_executesql;
go

declare @query_str varchar(100);
declare @param_def varchar(100);
exec sp_executesql @query_str, @param_def;
go

exec sp_prepexec;
go

declare @handle int;
exec sp_prepexec @handle output;
go

declare @handle int;
exec sp_prepexec @handle output, N'@a int';
go
