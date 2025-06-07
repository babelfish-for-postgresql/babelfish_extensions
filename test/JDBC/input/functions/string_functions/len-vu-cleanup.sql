DROP TRIGGER tr_binary_length
GO
DROP TABLE binary_trigger_dest
GO
DROP TABLE binary_trigger_source
GO
DROP TABLE binary_computed
GO
DROP FUNCTION get_binary_length
GO
DROP PROCEDURE check_binary_length
GO
DROP VIEW binary_lengths
GO
DROP TYPE BinaryUDT
GO
DROP TABLE binary_len_test
GO

-- Drop Triggers
DROP TRIGGER len_tr_ValidateLength;
GO

-- Drop Views
DROP VIEW len_basic_view;
DROP VIEW len_udt_view;
DROP VIEW len_indexed_view;
GO

-- Drop Functions
DROP FUNCTION len_fn_GetTotalLength;
DROP FUNCTION len_fn_GetLengthCategory;
DROP FUNCTION len_fn_GetAnalysis;
GO

-- Drop Stored Procedures
DROP PROCEDURE len_sp_AnalyzeLengths;
DROP PROCEDURE len_sp_ValidateAndInsert;
GO

-- Drop Tables
DROP TABLE len_constrained_test;
DROP TABLE len_computed_test;
DROP TABLE len_source_data;
DROP TABLE len_number_test;
DROP TABLE len_udt_t3;
DROP TABLE len_t2;
DROP TABLE len_t1;
GO

-- Drop User-Defined Types (after dropping all dependent objects)
DROP TYPE EmailAddress;
DROP TYPE PhoneNumber;
DROP TYPE FullName;
DROP TYPE Description;
DROP TYPE Unicode_Description;
DROP TYPE ShortCode;
DROP TYPE LongText;
DROP TYPE UnicodeCode;
GO
