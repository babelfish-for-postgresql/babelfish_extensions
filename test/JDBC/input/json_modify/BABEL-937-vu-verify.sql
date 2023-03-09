-- Key exists, not append
select * from babel_937_not_append_kp
go

-- Key not exists, not append
select * from babel_937_not_append_knp_1
go
select * from babel_937_not_append_knp_2
go
select * from babel_937_not_append_knp_3
go

-- Key exists, append
select * from babel_937_append_kp_notarr_1
go
select * from babel_937_append_kp_notarr_2
go
select * from babel_937_append_kp_notarr_3
go

select * from babel_937_append_kp_arr
go

-- Key not exists, append
-- The sequence of the return json string keys may be different between Babelfish and T-SQL
select * from babel_937_append_knp_notarr_1
go
select * from babel_937_append_knp_notarr_2
go
select * from babel_937_append_knp_notarr_3
go

-- Tests to check if the function works for case-sensitive cases
select * from babel_937_case_sensitive_1
go
select * from babel_937_case_sensitive_2
go

--Test to check wrong keyword in the path argument
select * from babel_937_keyword_check
go

-- Test to check when there are spaces in path argument
select * from babel_937_spaces
go

-- To check multi function call query
select * from babel_937_multi_function
go

-- To check when expression is array type
select * from babel_937_test_array
go
