#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"
#include <gtest/gtest.h>
#include <sqlext.h>

using std::vector;
using std::pair;
using std::tuple;

// Read Only table
static const string RESULT_SET_RO_TABLE1 = "RESULT_SET_RO";

// Columns for the test table
static const  vector<pair<string,string>> RO_TABLE_COLUMNS = {
    {"id", "INT"},
    {"info", "VARCHAR(256) NOT NULL"},
    {"decivar", "NUMERIC(38,16)"}
  };

static const vector<tuple<int, string, float>> RO_TABLE_VALUES = {
    {1, "hello1", 1.1},
    {2, "hello2", 2.2},
    {3, "hello3", 3.3},
    {4, "hello4", 4.4}
  };

const string SELECT_RESULT_SET_RO_TABLE1 = SelectStatement(RESULT_SET_RO_TABLE1, { "*" }, {"id"}); // order by id

class Result_Set : public testing::Test {

  protected:
    static void SetUpTestSuite() {
      OdbcHandler test_setup;

      test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE",RESULT_SET_RO_TABLE1));
      test_setup.ExecQuery(CreateTableStatement(RESULT_SET_RO_TABLE1, RO_TABLE_COLUMNS));
      test_setup.ExecQuery(InsertStatement(RESULT_SET_RO_TABLE1, "(1, 'hello1', 1.1), (2, 'hello2', 2.2), (3, 'hello3', 3.3), (4, 'hello4', 4.4)"));
    }

    static void TearDownTestSuite() {
      OdbcHandler test_cleanup;

      test_cleanup.ConnectAndExecQuery(DropObjectStatement("TABLE",RESULT_SET_RO_TABLE1));
    }

};

// Setup function for SQLBindcol tests. 
// Execute query on the read only table and calls BindCol with a given col num as the argument. 
// It will also assert the given expected rcode and output the sql state. 
void SQLBindColTestSetup(const int col_num, const RETCODE expected_rcode, string* sql_state) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1);

  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), col_num, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, expected_rcode);

  *sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
}

// Connects the odbcHandler, allocate the stmt handle, and set the stmt handle to be scrollable
void ConnectAndSetScrollable(OdbcHandler* odbcHandler) {
  RETCODE rcode;
  odbcHandler->Connect(true);
  rcode = SQLSetStmtAttr(odbcHandler->GetStatementHandle(), 
                          SQL_ATTR_CURSOR_SCROLLABLE, 
                          (SQLPOINTER) SQL_SCROLLABLE,
                          0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler->GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

void ConnectAndSetScrollableWithConcurLock(OdbcHandler* odbcHandler) {
  RETCODE rcode;
  
  ConnectAndSetScrollable(odbcHandler);
  rcode = SQLSetStmtAttr(odbcHandler->GetStatementHandle(), SQL_ATTR_CONCURRENCY,
                             (SQLPOINTER)SQL_CONCUR_LOCK ,0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler->GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Tests SQLBindCol on a succesful state. 
TEST_F(Result_Set, SQLBindCol_Successful) {
  string sql_state; 
  
  SQLBindColTestSetup(1, SQL_SUCCESS, &sql_state);
  ASSERT_EQ(sql_state, "00000");
}

// Tests SQLBindCol when ColumnNumber is 0 and it is not a bookmark column
TEST_F(Result_Set, SQLBindCol_NotBookmark) {
  string sql_state; 

  // Bind column and assert that it returns error 07006
  SQLBindColTestSetup(0, SQL_ERROR, &sql_state);
  ASSERT_EQ(sql_state, "07006");
}

// Tests SQLBindCol when ColumnNumber argument exceeds max number of columns in result set
TEST_F(Result_Set, SQLBindCol_ExceedMaxCol) {
  string sql_state; 

  // Bind column and assert that it returns error 07009
  SQLBindColTestSetup(10000, SQL_ERROR, &sql_state);
  ASSERT_EQ(sql_state, "07009");
}

// Tests SQLFetch when it iterates through all results
TEST_F(Result_Set, SQLFetch_SuccessfulIteration) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLCHAR info[256];
  SQLLEN info_indicator;
  SQLLEN id_indicator;

  vector<tuple<int, int, SQLPOINTER, int>> bind_columns = {
    {1, SQL_C_ULONG, &id, 0},
    {2, SQL_C_CHAR, &info, sizeof(info)}
  };
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));
  
  for (auto row_values : RO_TABLE_VALUES) {
    // Assert that it is able to fetch all rows with the correct values
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    auto& [id_val, info_val, decivar_val] = row_values;
    EXPECT_EQ(id, id_val);
    EXPECT_EQ(string((char*) info),info_val);
  }
  
  // Assert that SQLFetch returns SQL_NO_DATA
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Tests SQLFetch when a varchar variable gets truncated
TEST_F(Result_Set, SQLFetch_TruncatedVarchar) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLCHAR info[2];
  SQLLEN info_indicator;
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  
  // Bind the columns to variables
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 2, SQL_C_CHAR, &info, sizeof(info), &info_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that we get sql state 01004 when a varchar variable is truncated
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS_WITH_INFO) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "01004");
}

// Tests SQLFetch when a numeric datatype gets truncated
TEST_F(Result_Set, SQLFetch_TruncatedNumeric) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER decivar;
  SQLLEN decivar_indicator;
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  
  // Bind the columns to variables
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 3, SQL_C_ULONG, &decivar, 0, &decivar_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS_WITH_INFO) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that we get sql state 01S07 when a numeric datatype is truncated
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "01S07");
}

// Tests SQLFetch when there is an invalid cast during bindcol. 
TEST_F(Result_Set, SQLFetch_InvalidCast) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLLEN id_indicator;
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  
  // Bind the columns to variables
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 2, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that we get sql state 22018 when there is an invalid cast
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "22018");
}

// Tests SQLSetPos when SQL_ATTR_ROW_ARRAY_SIZE is set to 1.
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_ResultRowSize1) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  int id;
  SQLLEN id_indicator;
  
  // Setup, connect and set attributes for SQLSetPos
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  // Assert that we can retrieve the first row of the results but not the second.
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 1);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 2, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_ERROR);

  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY107");
}

// Tests SQLSetPos when SQL_ATTR_ROW_ARRAY_SIZE is set to 2.
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_ResultRowSize2) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  int id;
  SQLLEN id_indicator;

  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  rcode = SQLSetStmtAttr(odbcHandler.GetStatementHandle(),
                    SQL_ATTR_ROW_ARRAY_SIZE, 
                    (SQLPOINTER) 2,
                    SQL_IS_INTEGER);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  // Assert that we can retrieve the first and second row of the results but not the third.
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 2, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 3, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY107");

  // Assert that we can get the last set of items by calling another SQLFetch
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_POSITION, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 3);
}

// Tests that SQL_UPDATE OR SQL_DELETE option would not work when 
// SQL_ATTR_CONCURRENCY is set to read only (which should be the default value)
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_ErrorSqlAttrConcurrencyReadOnly) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 

  // Setup statement attributes and run the initial query
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  // Fetch result and assert that there is an error of state HY0902 when using SQL_UPDATE
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_UPDATE, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY092");

  // Fetch result and assert that there is an error of state HY0902 when using SQL_DELETE
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_DELETE, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY092");
}

// Tests that SQL_UPDATE option gives error 21S02
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_Sqlupdate21S02) {

  const string TEST_TABLE = "RESULT_SET_UPDATE21S02";
  const string TEST_SELECT = SelectStatement(TEST_TABLE, { "*" });
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(1), (2), (3), (4)"));

  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 

  // Setup attributes and initial query
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollableWithConcurLock(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(TEST_SELECT));

  // Fetch results and assert that a state of 21S02 is returned due to no variables being bounded
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_UPDATE, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "21S02");
  odbcHandler.FreeAllHandles(); // This is to release the concurrent lock. Otherwise dbObjects trying to drop the test table may block.
}

// Tests that SQL_UPDATE option works correctly
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_SqlupdateSuccessful) {
  
  const string TEST_TABLE = "RESULT_SET_UPDATE";
  const string TEST_SELECT = SelectStatement(TEST_TABLE, { "*" });
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(1), (2), (3), (4)"));

  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id = 10;
  SQLLEN id_indicator;

  // Setup
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollableWithConcurLock(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(TEST_SELECT));

  // Fetch and bind column to id and call SQLSetPos with SQL_UPDATE option
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_UPDATE, SQL_LOCK_NO_CHANGE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.FreeAllHandles());

  // Assert that the first item has changed to 10
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(TEST_SELECT));
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 10);
}

// Ensures that SQL_DELETE works correctly
// DISABLED: PLEASE SEE BABELFISH-97
TEST_F(Result_Set, DISABLED_SQLSetPos_SqldeleteSuccessful) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id;
  SQLLEN id_indicator;
  int num_rows_before = 0;
  int num_rows_after = 0;

  const string TEST_TABLE = "RESULT_SET_DELETE";
  const string TEST_SELECT = SelectStatement(TEST_TABLE, { "*" });
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(1), (2), (3), (4)"));
  
  // Setup num_rows_before
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(TEST_SELECT));

  // Count all the rows before delete for setup
  while (SQLFetch(odbcHandler.GetStatementHandle()) != SQL_NO_DATA) {
    num_rows_before++;
  }

  // Setup for SQLSetpos with SQL_Delete option
  ASSERT_NO_FATAL_FAILURE(odbcHandler.FreeAllHandles());
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollableWithConcurLock(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(TEST_SELECT));

  // Call SQLSetPos with SQL_DELETE option and ensure that it is succesful
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLSetPos(odbcHandler.GetStatementHandle(), 1, SQL_DELETE, SQL_LOCK_NO_CHANGE);
  EXPECT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  

  ASSERT_NO_FATAL_FAILURE(odbcHandler.FreeAllHandles());

  // Recount all rows and assert that there is one less than before
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(TEST_SELECT));
  while (SQLFetch(odbcHandler.GetStatementHandle()) != SQL_NO_DATA) {
    num_rows_after++;
  }
  ASSERT_EQ(num_rows_after, num_rows_before -1);
} 

// Ensures that SQLGetData works correctly
TEST_F(Result_Set, SQLGetData_Successful) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  // Setup
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  // Assert that SQLGetData retrieves the correct value
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  ASSERT_EQ(id, 1);
}

// Tests SQLGetData when a varchar variable gets truncated
TEST_F(Result_Set, SQLGetData_TruncatedVarchar) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLCHAR info[2];
  SQLLEN info_indicator;
  
  // Setup
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that we get sql state 01004 when a varchar variable is truncated
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 2, SQL_C_CHAR, &info, sizeof(info), &info_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS_WITH_INFO) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "01004");
}

// Tests SQLGetData when a numeric datatype gets truncated
TEST_F(Result_Set, SQLGetData_TruncatedNumeric) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER decivar;
  SQLLEN decivar_indicator;
  
  // Setup
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that we get sql state 01004 when a numeric datatype is truncated
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 3, SQL_C_ULONG, &decivar, 0, &decivar_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS_WITH_INFO) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "01S07");
}

// Tests SQLGetData when there is an invalid cast during bindcol. 
TEST_F(Result_Set, SQLGetData_InvalidCast) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLLEN id_indicator;
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  // Assert that we get sql state 22018 when there is an invalid cast
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 2, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT,odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "22018");
}

// Test SQLFetchScroll with Fetch First and Fetch Last options
// DISABLED: PLEASE SEE BABELFISH-98
TEST_F(Result_Set, DISABLED_SQLFetchScroll_FetchFirstAndFetchLast) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  int firstValue = std::get<0>(RO_TABLE_VALUES[0]);
  int lastValue = std::get<0>(RO_TABLE_VALUES[RO_TABLE_VALUES.size()-1]);

  // Setup
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  // Call SQLFetchScroll with SQL_FETCH_FIRST option and assert that the correct value is being returned
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_FIRST,  0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, firstValue);

  // Call SQLFetchScroll with SQL_FETCH_LAST option and assert that the correct value is being returned
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_LAST, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, lastValue);
}

// Test SQLFetchScroll with SQL_FETCH_NEXT and SQL_FETCH_PRIOR
// DISABLED: PLEASE SEE BABELFISH-98
TEST_F(Result_Set, DISABLED_SQLFetchScroll_FetchNextAndFetchPrior) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  // setup
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  int num_results = RO_TABLE_VALUES.size();
  // Move the cursor forward through all the results and assert the values retrieved are correct
  for (int i = 1; i <= num_results; i++) {
    rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_NEXT,  0);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[i-1]));
  }

  // Assert that there is no more data past the end
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_NEXT,  0);
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Move the cursor backwards through all the results and assert the values retrieved are correct
  for (int i = num_results; i > 0; i--) {
    rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_PRIOR,  0);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[i-1]));
  }

  // Assert that there is no more data before the beginning of the result set
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_PRIOR,  0);
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Test SQLFetchScroll with SQL_FETCH_ABSOLUTE
// DISABLED: PLEASE SEE BABELFISH-98
TEST_F(Result_Set, DISABLED_SQLFetchScroll_FetchAbsolute) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  // Setup connection
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  int num_results = RO_TABLE_VALUES.size();
  // Go through the whole table and assert that the correct values are retrieved 
  for (int i = 1; i <= num_results; i++) {
    rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_ABSOLUTE,  i);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[i-1]));
  }

  // Assert that we will move to row 2 and that the value of id is correct
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_ABSOLUTE,  2);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[1]));
}

// Test SQLFetchScroll with SQL_FETCH_RELATIVE
// DISABLED: PLEASE SEE BABELFISH-98
TEST_F(Result_Set, DISABLED_SQLFetchScroll_FetchRelative) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  // Setup
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  int num_results = RO_TABLE_VALUES.size();
  // Go through all the results and assert that the correct value for id is fetched
  for (int i = 1; i <= num_results; i++) {
    rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_RELATIVE,  1);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[i-1]));
  }

  // Move the cursor back by 2 rows and assert that the correct result is fetched
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_RELATIVE,  -2);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, std::get<0>(RO_TABLE_VALUES[1]));
  
  // Assert that SQL_NO_DATA is returned when the cursor is moved past before the beginning
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_RELATIVE,  -2);
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Tests SQLNumResultCols
TEST_F(Result_Set, SQLNumResultCols) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLSMALLINT num_cols;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  rcode = SQLNumResultCols(odbcHandler.GetStatementHandle(), &num_cols);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(num_cols, RO_TABLE_COLUMNS.size());
}

// Tests SQLCloseCursor
// DISABLED: PLEASE SEE BABELFISH-99
TEST_F(Result_Set, DISABLED_SQLCloseCursor) {
  OdbcHandler odbcHandler;
  RETCODE rcode; 
  string sql_state; 
  SQLINTEGER id;
  SQLLEN id_indicator;

  // setup
  ASSERT_NO_FATAL_FAILURE(ConnectAndSetScrollable(&odbcHandler));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SELECT_RESULT_SET_RO_TABLE1));

  // Assert that it is unable the fetch after closing the cursor and that the correct sql state
  // has been produced
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_ABSOLUTE,  1);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLCloseCursor(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLFetchScroll(odbcHandler.GetStatementHandle(), SQL_FETCH_ABSOLUTE,  2);
  ASSERT_EQ(rcode, SQL_ERROR);
  
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY010");
}

// Test SQLDescribeCol
// DISABLED: PLEASE SEE BABELFISH-100 
TEST_F(Result_Set, DISABLED_SQLDescribeCol) { 
  OdbcHandler odbcHandler;
  SQLCHAR col_name[256];
  SQLSMALLINT name_length;
  SQLSMALLINT data_type;
  SQLULEN col_size;
  SQLSMALLINT dec_digits;
  SQLSMALLINT nullable_ptr;
  RETCODE rcode;
  
  // Setup
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SELECT_RESULT_SET_RO_TABLE1));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // The expected values would need to be updated if the RO_TABLE_COLUMNS change.
  vector<tuple<string,int, int, int, int, int>> expected_values = {
    {"id", 2, SQL_INTEGER, 10, 0, SQL_NULLABLE},
    {"info", 4, SQL_VARCHAR, 256, 0, SQL_NO_NULLS},
    {"decivar", 7, SQL_NUMERIC, 38, 16, SQL_NULLABLE}
  };

  int ordinal {0};
  for (auto column_info : expected_values) {
    ++ordinal;
    rcode = SQLDescribeCol(odbcHandler.GetStatementHandle(),
                          ordinal,
                          col_name,
                          sizeof(col_name),
                          &name_length,
                          &data_type,
                          &col_size,
                          &dec_digits,
                          &nullable_ptr);
    ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
    auto& [name, name_len, sql_type, size, digits, nullable] = column_info;
    EXPECT_EQ(string( (char*) col_name), name);
    EXPECT_EQ(name_length, name_len);
    EXPECT_EQ(data_type,sql_type );
    EXPECT_EQ(col_size, size);
    EXPECT_EQ(dec_digits,digits);
    EXPECT_EQ(nullable_ptr,nullable);
  }
}

TEST_F(Result_Set, SQLMoreResults_BatchedQueries) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLLEN id_indciator = 0;
  string sql_state;
  int id = 0;

  string batch_query = SelectStatement(RESULT_SET_RO_TABLE1, { "*" }, {}, "id = 1") + " ; " + 
                       SelectStatement(RESULT_SET_RO_TABLE1, { "*" }, {}, "id = 2");

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));

  rcode = SQLPrepare(odbcHandler.GetStatementHandle(),(SQLCHAR*) batch_query.c_str(), SQL_NTS); 
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLExecute(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 1);
  
  rcode = SQLMoreResults(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, 0);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 2);

  rcode = SQLMoreResults(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}
