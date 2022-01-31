#include "odbc_handler.h"
#include <gtest/gtest.h>
#include <sqlext.h>

static const int BUFFER = 255;

class SQLGetInfoTest : public testing::Test{
  
};

// Sets up SQLGetInfo test whose option returns a character string
void SqlGetInfoTestSetupString(OdbcHandler &odbcHandler, SQLSMALLINT info_type,
                          char* output, SQLSMALLINT* str_length) {

  RETCODE rcode;
  odbcHandler.Connect();

  rcode = SQLGetInfo(odbcHandler.GetConnectionHandle(), info_type, output, BUFFER, str_length);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);
}

// Sets up SQLGetInfo test whose option returns a integer
void SqlGetInfoTestSetupInteger(OdbcHandler &odbcHandler, SQLSMALLINT info_type,
                          SQLUINTEGER* output) {

  RETCODE rcode;
  odbcHandler.Connect();

  rcode = SQLGetInfo(odbcHandler.GetConnectionHandle(), info_type, output, sizeof(SQLINTEGER), 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);
}

// Get the server name through a query
void GetServerName(char* servername) {

  RETCODE rcode;
  OdbcHandler odbcHandler;
  odbcHandler.ConnectAndExecQuery("SELECT @@SERVERNAME");
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_CHAR, servername, BUFFER, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Get the username through a query
void GetUserName(char* username) {

  RETCODE rcode;
  OdbcHandler odbcHandler;
  odbcHandler.ConnectAndExecQuery("SELECT CURRENT_USER");
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_CHAR, username, BUFFER, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Helper function to print out error messages for SQLGetInfoTests
string SqlGetInfoSupportError(string sqlgetinfo_option, string supported_feature) {

  return "SQLGetInfo with " + sqlgetinfo_option + " stated that it does not support " + 
          supported_feature + " when it should";
}

// Tests if SQLGetInfo retrieves the correct server name with SQL_SERVER_NAME option
// DISABLED: PLEASE SEE BABELFISH-125
TEST_F(SQLGetInfoTest, DISABLED_SQLGetInfo_SQL_SERVER_NAME) {

  OdbcHandler odbcHandler;
  char output[BUFFER];
  char expected[BUFFER];

  ASSERT_NO_FATAL_FAILURE(GetServerName(expected));
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupString(odbcHandler, SQL_SERVER_NAME, output, 0));
  ASSERT_EQ(string(output), string(expected));
}

// Tests if SQLGetInfo retrieves the correct server name with SQL_USER_NAME option
// DISABLED: PLEASE SEE BABELFISH-126
TEST_F(SQLGetInfoTest, DISABLED_SQLGetInfo_SQL_USER_NAME) {

  OdbcHandler odbcHandler;
  char output[BUFFER];
  char expected[BUFFER];

  ASSERT_NO_FATAL_FAILURE(GetUserName(expected));
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupString(odbcHandler, SQL_USER_NAME, output, 0));
  ASSERT_EQ(string(output), string(expected));
}

// Tests if SQLGetInfo retrieves the correct value for SQL_DATA_SOURCE_READ_ONLY
TEST_F(SQLGetInfoTest, SQLGetInfo_SQL_DATA_SOURCE_READ_ONLY) {

  OdbcHandler odbcHandler;
  char output[BUFFER];
  string expected = "N"; //The BBF cluster used for test should not be read only

  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupString(odbcHandler, SQL_DATA_SOURCE_READ_ONLY, output, 0));
  ASSERT_EQ(string(output), expected);
}

// Tests if SQLGetInfo retrieves the correct values for SQL_CREATE_TABLE. 
// NOTE: Assertions may need to be redefined based on BBF settings
TEST_F(SQLGetInfoTest, SQLGetInfo_SQL_CREATE_TABLE) {
  OdbcHandler odbcHandler;
  SQLUINTEGER output;
  string sqlgetinfo_option = "SQL_CREATE_TABLE";
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupInteger(odbcHandler, SQL_CREATE_TABLE, &output));
  EXPECT_TRUE(output & SQL_CT_CREATE_TABLE) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_CT_CREATE_TABLE");
}

// Tests if SQLGetInfo retrieves the correct values for SQL_DROP_TABLE. 
// NOTE: Assertions may need to be redefined based on BBF settings
TEST_F(SQLGetInfoTest, SQLGetInfo_SQL_DROP_TABLE) {
  OdbcHandler odbcHandler;
  SQLUINTEGER output = 0;
  string sqlgetinfo_option = "SQL_DROP_TABLE";
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupInteger(odbcHandler, SQL_DROP_TABLE, &output));
  EXPECT_TRUE(output & SQL_DT_DROP_TABLE) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_DT_DROP_TABLE");
}

// Tests if SQLGetInfo retrieves the correct values for SQL_ALTER_TABLE. 
// NOTE: Assertions may need to be redefined based on BBF settings
TEST_F(SQLGetInfoTest, SQLGetInfo_SQL_ALTER_TABLE) {
  OdbcHandler odbcHandler;
  SQLUINTEGER output = 0;
  string sqlgetinfo_option = "SQL_ALTER_TABLE";
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupInteger(odbcHandler, SQL_ALTER_TABLE, &output));
  EXPECT_TRUE(output & SQL_AT_CONSTRAINT_NAME_DEFINITION) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_AT_CONSTRAINT_NAME_DEFINITION");
  EXPECT_TRUE(output & SQL_AT_ADD_COLUMN_SINGLE) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_AT_ADD_COLUMN_SINGLE");
  EXPECT_TRUE(output & SQL_AT_ADD_CONSTRAINT) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_AT_ADD_CONSTRAINT");
  EXPECT_TRUE(output & SQL_AT_ADD_TABLE_CONSTRAINT) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_AT_ADD_TABLE_CONSTRAINT");
  EXPECT_TRUE(output & SQL_AT_CONSTRAINT_NAME_DEFINITION) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_AT_CONSTRAINT_NAME_DEFINITION");
}

// Tests if SQLGetInfo retrieves the correct values for SQL_INSERT_STATEMENT. 
// NOTE: Assertions may need to be redefined based on BBF settings
TEST_F(SQLGetInfoTest, SQLGetInfo_SQL_INSERT_STATEMENT) {

  OdbcHandler odbcHandler;
  SQLUINTEGER output = 0;
  string sqlgetinfo_option = "SQL_INSERT_STATEMENT";
  ASSERT_NO_FATAL_FAILURE(SqlGetInfoTestSetupInteger(odbcHandler, SQL_INSERT_STATEMENT, &output));
  EXPECT_TRUE(output & SQL_IS_INSERT_LITERALS) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_IS_INSERT_LITERALS");
  EXPECT_TRUE(output & SQL_IS_INSERT_SEARCHED) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_IS_INSERT_SEARCHED");
  EXPECT_TRUE(output & SQL_IS_SELECT_INTO) << SqlGetInfoSupportError(sqlgetinfo_option, "SQL_IS_SELECT_INTO");
}
