-- Test PRINT with T-sql procedures --
-- Printing a pre-defined text
CREATE PROCEDURE tsql_print_text AS
    PRINT 'Pre-defined text for tsql_print_text'
GO
EXEC tsql_print_text
GO

-- Printing a user input text
CREATE PROCEDURE tsql_print_message(@message varchar(50)) AS
BEGIN 
    PRINT @message 
END;
GO
EXEC tsql_print_message 'Testing message for tsql_print_message'
GO

-- Printing a pre-defined and a user input text
CREATE PROCEDURE tsql_print_message_and_text(@message varchar(50)) AS 
BEGIN 
    PRINT 'Pre-defined text for tsql_print_message_and_text. User input: '+ @message
END
GO
EXEC tsql_print_message_and_text 'Testing message for tsql_print_message_and_text'
GO

-- Making a call to another function that prints
CREATE PROCEDURE tsql_print_function AS
    EXECUTE tsql_print_text
GO
EXEC tsql_print_function
GO

-- Cleanup --
DROP PROCEDURE tsql_print_text;
DROP PROCEDURE tsql_print_message;
DROP PROCEDURE tsql_print_message_and_text;
DROP PROCEDURE tsql_print_function;
GO
