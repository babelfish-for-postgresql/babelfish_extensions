#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"
#include <sqlext.h>
#include <gtest/gtest.h>

// Read Only table
static const string DIR_STMT_RO_TABLE1 = "DIR_EXEC_STMT_TABLE_RO_1";

class Direct_Executed_Statements : public testing::Test{

  protected:

  static void SetUpTestSuite() {
    OdbcHandler test_setup;

    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE",DIR_STMT_RO_TABLE1));
    test_setup.ExecQuery(CreateTableStatement(DIR_STMT_RO_TABLE1, {{"id", "int"}}));
    test_setup.ExecQuery(InsertStatement(DIR_STMT_RO_TABLE1, "(1), (2), (3)"));
  }

  static void TearDownTestSuite() {
    OdbcHandler test_cleanup;

    test_cleanup.ConnectAndExecQuery(DropObjectStatement("TABLE",DIR_STMT_RO_TABLE1));
  }
};

// Create statement, execute query, call with SQL_CLOSE option
TEST_F(Direct_Executed_Statements, SQLFreeStmt_SQL_CLOSE_1) {
  OdbcHandler odbcHandler;
  RETCODE rcode;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SelectStatement(DIR_STMT_RO_TABLE1, { "*" })));
  
  rcode = SQLFreeStmt(odbcHandler.GetStatementHandle(), SQL_CLOSE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Create statement, execute query, bind column, call SQL_CLOSE option
TEST_F(Direct_Executed_Statements, SQLFreeStmt_SQL_CLOSE_2) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  SQLINTEGER id;
  SQLLEN id_indicator;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SelectStatement(DIR_STMT_RO_TABLE1, { "*" })));

  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 1);

  // Assert SQL_CLOSE to be succesful
  rcode = SQLFreeStmt(odbcHandler.GetStatementHandle(), SQL_CLOSE);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // Assert that statement is closed and cannot fetch new data after another bindcol call.
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_ERROR);

  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "HY010");
}

// Tests SQLFreeStmt with unbind option
TEST_F(Direct_Executed_Statements, SQLFreeStmt_2_SQL_UNBIND) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  SQLINTEGER id;
  SQLLEN id_indicator;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(SelectStatement(DIR_STMT_RO_TABLE1, { "*" })));

  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 1);

  // Assert SQL_UNBIND to be succesful and SQLFetch will result in retrieving 
  // the first result (id == 1). 
  rcode = SQLFreeStmt(odbcHandler.GetStatementHandle(), SQL_UNBIND);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(id, 1);

  // Assert that we can still bind a column and fetch and it will not result in an error 
  rcode = SQLBindCol(odbcHandler.GetStatementHandle(), 1, SQL_C_ULONG, &id, 0, &id_indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

// Tests SQLExecDirect when refering to a non-existant table
TEST_F(Direct_Executed_Statements,SQLExecDirect_InvalidTable ) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "SELECT * FROM NonExistantTable";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 

  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) query.c_str(),
                         SQL_NTS);

  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "42000");
}

// Tests SQLExecDirect when creating an already existing table
TEST_F(Direct_Executed_Statements,SQLExecDirect_AlreadyExistingTable) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "CREATE TABLE " + DIR_STMT_RO_TABLE1 + "(id int)";
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) query.c_str(),
                         SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);
  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "42S01");
}

// Tests SQLExecDirect when using a non-valid sql statement
TEST_F(Direct_Executed_Statements, SQLExecDirect_NotValidSqlStatement) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "ABC";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) query.c_str(),
                         SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "42000");
}

// Tests SQLExecDirect when dividing by zero
TEST_F(Direct_Executed_Statements, SQLExecDirect_DivisionByZero) {

  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;
  string query = "SELECT (10/0)";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) query.c_str(),
                         SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle());
  ASSERT_EQ(sql_state, "22012");
}

// Tests SQLRowCount when using an update statement
TEST_F(Direct_Executed_Statements, SQLRowCount_UPDATE) {
  OdbcHandler odbcHandler;
  SQLLEN row_count;

  const string TEST_TABLE = "DIR_EXEC_STMT_TABLE_UPDATE";

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(0), (0), (1)"));

  string query = "UPDATE " + TEST_TABLE + " SET id = 100 where id=0";
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(query));

  SQLRowCount(odbcHandler.GetStatementHandle(), &row_count);
  ASSERT_EQ(row_count, 2);
}

// Tests SQLRowCount when using an insert statement
TEST_F(Direct_Executed_Statements, SQLRowCount_INSERT) {
  OdbcHandler odbcHandler;
  SQLLEN row_count;
  
  const string TEST_TABLE = "DIR_EXEC_STMT_TABLE_INSERT";

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, "(100)")));

  SQLRowCount(odbcHandler.GetStatementHandle(), &row_count);
  ASSERT_EQ(row_count, 1);
}

// Tests SQLRowCount when using a Delete statement
TEST_F(Direct_Executed_Statements, SQLRowCount_DELETE) {
  OdbcHandler odbcHandler;
  SQLLEN row_count;
  
  const string TEST_TABLE = "DIR_EXEC_STMT_TABLE_DELETE";
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(0), (0), (1)"));

  string query = "DELETE FROM " + TEST_TABLE + " WHERE id = 1";
  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(query));

  SQLRowCount(odbcHandler.GetStatementHandle(), &row_count);
  ASSERT_EQ(row_count, 1);
}

// Tests SQLRowCount when using a select statement
TEST_F(Direct_Executed_Statements, SQLRowCount_SELECT) {
  OdbcHandler odbcHandler;
  SQLLEN row_count;

  const string TEST_TABLE = "DIR_EXEC_STMT_TABLE_SELECT";
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(0), (0), (1)"));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" })));

  SQLRowCount(odbcHandler.GetStatementHandle(), &row_count);
  ASSERT_EQ(row_count, -1);
}

// Tests SQLRowCount when using a select statement and retrieving selected rows
// SQLRowCount reports number of rows when all rows were 'consumed'
// DISABLED: Investigate the expected difference.
TEST_F(Direct_Executed_Statements, DISABLED_SQLRowCount_SELECT_CONSUME_ROWS) {
  OdbcHandler odbcHandler;
  SQLLEN row_count;
  RETCODE rcode;

  const string TEST_TABLE = "DIR_EXEC_STMT_TABLE_SELECT_CONSUME_ROWS";
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));
  ASSERT_NO_FATAL_FAILURE(dbObjects.Insert(TEST_TABLE,"(0), (0), (1)"));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true)); 
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" })));
  while ((rcode = SQLFetch(odbcHandler.GetStatementHandle())) == SQL_SUCCESS) {
  }

  EXPECT_EQ(rcode, SQL_NO_DATA) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  
  SQLRowCount(odbcHandler.GetStatementHandle(), &row_count);
  ASSERT_EQ(row_count, 3);
}
