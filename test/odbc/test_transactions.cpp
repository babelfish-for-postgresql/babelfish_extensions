#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"
#include <sqlext.h>
#include <gtest/gtest.h>

class Transactions : public testing::Test {

  protected:

  static void SetUpTestSuite() {
  }

  static void TearDownTestSuite() {
  }
};

// Complete a transaction and assert that the values were correctly inserted
// DISABLED: Please see BABELFISH-113 
TEST_F(Transactions, DISABLED_SQLEndTran_Commit) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string query{};

  const string TEST_TABLE = "TRANSACTION_TABLE_W_1";
  const string ID_COL = "id";

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{ID_COL, "INT"}}));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect());

  // Disable autocommit
  rcode = SQLSetConnectAttr(odbcHandler.GetConnectionHandle(), SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.AllocateStmtHandle());
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, "(1)")));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, "(2)")));

  // Commit the transaction
  rcode = SQLEndTran(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle(), SQL_COMMIT);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" }, {ID_COL}))); // order by id

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  int col_num = 1;
  int buf;
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), col_num, SQL_C_ULONG, &buf, 0, nullptr);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(buf, 1);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLGetData(odbcHandler.GetStatementHandle(), col_num, SQL_C_ULONG, &buf, 0, nullptr);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(buf, 2);
}

// Rollbacks back the transaction and assert that nothing was created
// DISABLED: Please see BABELFISH-113 
TEST_F(Transactions, DISABLED_SQLEndTran_Rollback) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  
  const string TEST_TABLE = "TRANSACTION_TABLE_RO_1";
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect());

  // Disable autocommit
  rcode = SQLSetConnectAttr(odbcHandler.GetConnectionHandle(), SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.AllocateStmtHandle());
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, "(1)")));

  // Rollback the transaction
  rcode = SQLEndTran(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle(), SQL_ROLLBACK);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" })));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

// Attempt to disconnect during a transaction
// DISABLED: Please see BABELFISH-113 
TEST_F(Transactions, DISABLED_SQL_DisconnectAttemptDuringTransaction) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  string sql_state;

  const string TEST_TABLE = "TRANSACTION_TABLE_RO_2";
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(TEST_TABLE, {{"id", "INT"}}));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect());

  // Disable autocommit
  rcode = SQLSetConnectAttr(odbcHandler.GetConnectionHandle(), SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.AllocateStmtHandle());
  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(InsertStatement(TEST_TABLE, "(1)")));

  rcode = SQLDisconnect(odbcHandler.GetConnectionHandle());
  ASSERT_EQ(rcode, SQL_ERROR);

  sql_state = odbcHandler.GetSqlState(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle());
  ASSERT_EQ(sql_state, "25000");

  // Rollback transaction
  rcode = SQLEndTran(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle(), SQL_ROLLBACK);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ExecQuery(SelectStatement(TEST_TABLE, { "*" })));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
}
