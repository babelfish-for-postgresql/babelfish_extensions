#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"
#include <sqlext.h>
#include <gtest/gtest.h>

using std::vector;
using std::pair;

static const string SQLPREPTABLE_RO_1 = "sqlprepstmts_ro";
// Columns for the test table
static const  vector<pair<string,string>> RO_TABLE_COLUMNS = {
    {"id", "INT"},
    {"info", "VARCHAR(256) NOT NULL"},
    {"decivar", "NUMERIC(38,16)"}
  };

class Prepared_Statements : public testing::Test{

  protected:

  static void SetUpTestSuite() {

    OdbcHandler test_setup;
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE",SQLPREPTABLE_RO_1));
    test_setup.ExecQuery(CreateTableStatement(SQLPREPTABLE_RO_1, RO_TABLE_COLUMNS));
    test_setup.ExecQuery(InsertStatement(SQLPREPTABLE_RO_1, "(1, 'hello1', 1.1), (2, 'hello2', 2.2), (3, 'hello3', 3.3), (4, 'hello4', 4.4)"));
  }

  static void TearDownTestSuite() {

    OdbcHandler test_cleanup;
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("TABLE",SQLPREPTABLE_RO_1));
  }
};

RETCODE SetupPreparedStatements(OdbcHandler& odbcHandler, const string& query) {

  odbcHandler.Connect(true);

  return SQLPrepare(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
}

// Tests SQLPrepare is successful
TEST_F(Prepared_Statements, SQLPrepare_Success) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1;

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Tests SQLNumParams for an error when it is called before SQLPrepare
TEST_F(Prepared_Statements, SQLNumParams_Error) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  int num_params;
  string sql_state;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLNumParams(odbcHandler.GetStatementHandle(), (SQLSMALLINT*) &num_params);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());

  ASSERT_EQ(sql_state, "HY010");
}

// Tests SQLNumParams succesfully for 1 paramater
TEST_F(Prepared_Statements, SQLNumParams_Success1) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLSMALLINT num_params;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + "  WHERE id = ?";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLNumParams(odbcHandler.GetStatementHandle(), &num_params);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(num_params, 1);
}

// Tests SQLNumParams succesfully for 2 parameters
TEST_F(Prepared_Statements, SQLNumParams_Success2) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLSMALLINT num_params;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + " WHERE id = ? AND info = ?";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLNumParams(odbcHandler.GetStatementHandle(), &num_params);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(num_params, 2);
}

// Tests SQLNumParams succesfully for 3 parameters
TEST_F(Prepared_Statements, SQLNumParams_Success3) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLSMALLINT num_params;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + "  WHERE id = ? AND info = ? AND decivar = ?";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLNumParams(odbcHandler.GetStatementHandle(),  &num_params);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(num_params, 3);
}

// Tests SQLDescribeParam for on success
// DISABLED: PLEASE SEE BABELFISH-109
TEST_F(Prepared_Statements, DISABLED_SQLDescribeParam_Success) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLSMALLINT data_type, decimal_digits, nullable;
  SQLULEN param_size;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + "  WHERE id = ? AND info = ? AND decivar = ?";
  
  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Does not check for nullable because SQLDescribeParam uses the IPD descriptor handle. Not all drivers support automatic
  // population of the IPD. Asserting for nullness or non-nullness will be driver dependant.
  rcode = SQLDescribeParam(odbcHandler.GetStatementHandle(), 1, &data_type, &param_size, &decimal_digits, &nullable );
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(data_type, SQL_INTEGER);
  ASSERT_EQ(param_size, 10);
  ASSERT_EQ(decimal_digits, 0);

  rcode = SQLDescribeParam(odbcHandler.GetStatementHandle(), 2, &data_type, &param_size, &decimal_digits, &nullable );
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(data_type, SQL_VARCHAR);
  ASSERT_EQ(param_size, 256);
  ASSERT_EQ(decimal_digits, 0); 

  rcode = SQLDescribeParam(odbcHandler.GetStatementHandle(), 3, &data_type, &param_size, &decimal_digits, &nullable );
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(data_type, SQL_NUMERIC);
  ASSERT_EQ(param_size, 38);
  ASSERT_EQ(decimal_digits, 16);
  
}

// Tests SQLDescribeParam for error 21S01
// DISABLED: PLEASE SEE BABELFISH-110
TEST_F(Prepared_Statements, DISABLED_SQLDescribeParam_21S01) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  SQLSMALLINT data_type, decimal_digits, nullable;
  SQLULEN param_size;
  string query = "INSERT INTO " + SQLPREPTABLE_RO_1 + " VALUES (?, ?, ?, ?)";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLDescribeParam(odbcHandler.GetStatementHandle(), 3, &data_type, &param_size, &decimal_digits, &nullable );
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "21S01");
  
}

// Tests SQLDescribeParam for error 07009 (no parameters)
TEST_F(Prepared_Statements, SQLDescribeParam_Noparams) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLSMALLINT data_type, decimal_digits, nullable;
  SQLULEN param_size;
  string sql_state;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + " ";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLDescribeParam(odbcHandler.GetStatementHandle(), 1, &data_type, &param_size, &decimal_digits, &nullable );
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "07009");
}

// Tests bind parameters when parameters are binded successfully.
TEST_F(Prepared_Statements, SQLBindParameter_Success) {

  OdbcHandler odbcHandler;
  RETCODE rcode;

  SQLUINTEGER id_input = 1;
  SQLCHAR info_input[256] = "hello1";
  SQLFLOAT decivar_input = 1.1;
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + "  WHERE id = ? AND info = ? AND decivar = ?";

  rcode = SetupPreparedStatements(odbcHandler, query);
  
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 1,SQL_PARAM_INPUT, SQL_C_ULONG, SQL_INTEGER, 10, 0,
  &id_input,0,0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 2, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR,  256, 0,
  info_input,256, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 3, SQL_PARAM_INPUT, SQL_C_NUMERIC, SQL_NUMERIC, 38,  16,
  &decivar_input, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Tests SQLExecute when it is used successfully. 
TEST_F(Prepared_Statements, SQLExecute_Success) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLUINTEGER id_input = 1;
  SQLCHAR info_input[256] = "hello1";

  int id_out;
  SQLCHAR info_out[256];
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + "  WHERE id = ? AND info = ?";
  
  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 1,SQL_PARAM_INPUT, SQL_C_ULONG, SQL_INTEGER, 10, 0,
  &id_input,0,0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 2, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR,  256, 0,
  info_input,256, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);;

  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id_out, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id_out, id_input);

  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 2, SQL_C_CHAR, info_out, sizeof(info_out), 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(string((char*) info_out), string((char*)info_input));
}

// Tests SQLExecute with division by zero
TEST_F(Prepared_Statements, SQLExecute_DivisionByZero) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "SELECT (10/0)";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "22012");

}

// Tests SQLExecute with an already existing table
TEST_F(Prepared_Statements, SQLExecute_AlreadyExistingTable) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "CREATE TABLE " + SQLPREPTABLE_RO_1 + " (id int);";

  rcode = SetupPreparedStatements(odbcHandler, query);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "42S01");
  
}

// Tests SQLExecute with a not valid sql statement
// DISABLED: PLEASE SEE: BABELFISH-111
TEST_F(Prepared_Statements, DISABLED_SQLExecute_NotValidSqlStatement) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLPrepare(odbcHandler.GetStatementHandle(),(SQLCHAR*) "ABC", SQL_NTS); 
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "42000");
  
}

// SQLMoreResults with an array as an input for a prepared statement
TEST_F(Prepared_Statements, SQLMoreResults_BatchedArrayParamQueries) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  const int ARRAY_SIZE = 4;
  int id_input[4] = {1,2,3,4};
  string query = "SELECT * FROM " + SQLPREPTABLE_RO_1 + " WHERE id = ?";
  int id_out;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLSetStmtAttr(odbcHandler.GetStatementHandle(), SQL_ATTR_PARAM_BIND_TYPE, SQL_PARAM_BIND_BY_COLUMN, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetStmtAttr(odbcHandler.GetStatementHandle(), SQL_ATTR_PARAMSET_SIZE, (SQLPOINTER) ARRAY_SIZE, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLPrepare(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLBindParameter(odbcHandler.GetStatementHandle(), 1, SQL_PARAM_INPUT, SQL_C_ULONG, SQL_INTEGER, 10, 0, id_input, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle()); 
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id_out, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id_out, 1);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Should be able to call SQLMoreResults ARRAY_SIZE -1 times (since SQLExecute should call the first result set);
  for(int i = 0; i < ARRAY_SIZE - 1; i++) {

    rcode = SQLMoreResults(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

    rcode = SQLFetch(odbcHandler.GetStatementHandle()); 
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

    rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id_out, 0, 0);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ASSERT_EQ(id_out, i + 2);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
  }
  
  rcode = SQLMoreResults(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}