#include "odbc_handler.h"
#include "database_objects.h"
#include "query_generator.h"
#include <sqlext.h>
#include <gtest/gtest.h>

class Diagnostics : public testing::Test {
  protected:

  static void SetUpTestSuite() {
  }

  static void TearDownTestSuite() {
  }
};

TEST_F(Diagnostics, SQLGetDiagRec_Connection) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER rec_num = 0;
  SQLINTEGER   native;
  SQLCHAR      state[7];
  SQLCHAR      info[256];
  SQLSMALLINT  len;
  string conn_str_incorrect_creds = "DRIVER={" + odbcHandler.GetDriver() + "};SERVER=" + odbcHandler.GetServer() + "," + odbcHandler.GetPort() + ";UID=nonexistentuser;PWD=incorrectpassword;DATABASE=" + odbcHandler.GetDbname();

  ASSERT_NO_FATAL_FAILURE(odbcHandler.AllocateEnvironmentHandle());
  ASSERT_NO_FATAL_FAILURE(odbcHandler.AllocateConnectionHandle());
  rcode = SQLDriverConnect(odbcHandler.GetConnectionHandle(), nullptr, (SQLCHAR *) conn_str_incorrect_creds.c_str(), SQL_NTS, nullptr, 0, nullptr, SQL_DRIVER_NOPROMPT);
  ASSERT_EQ(rcode, SQL_ERROR);

  rcode = SQLGetDiagRec(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle(), ++rec_num, state, &native, info, sizeof(info), &len);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_DBC, rcode);
  // The SQL Server and BBF SQL State errors differ, but that's okay; these tests are intended to test ODBC functionality, not error mapping
  // Thus, we are not asserting error state equality. BBF should at least return some sort of state though, so we check for a non-empty string
  ASSERT_TRUE(string((const char*) state).length() > 0);
}

TEST_F(Diagnostics, SQLGetDiagRec_UnsuccessfulStatement) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER rec_num = 0;
  SQLINTEGER   native;
  SQLCHAR      state[7];
  SQLCHAR      info[256];
  SQLSMALLINT  len;
  string query = "SELECT ORDER BY INCORRECT SYNTAX";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  rcode = SQLGetDiagRec(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle(), ++rec_num, state, &native, info, sizeof(info), &len);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_STREQ((const char*) state, "42000");

  rcode = SQLGetDiagRec(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle(), ++rec_num, state, &native, info, sizeof(info), &len);
  ASSERT_EQ(rcode, SQL_NO_DATA);
}

TEST_F(Diagnostics, SQLGetDiagRec_Error) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER   native;
  SQLCHAR      state[7];
  SQLCHAR      info[256];
  SQLSMALLINT  len;
  string query = "SELECT ORDER BY INCORRECT SYNTAX";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  // Record number must be > 0
  SQLINTEGER rec_num = -1;
  rcode = SQLGetDiagRec(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle(), rec_num, state, &native, info, sizeof(info), &len);
  ASSERT_EQ(rcode, SQL_ERROR);
}

TEST_F(Diagnostics, SQLGetDiagField_SuccessfulStatement) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER rec_num = 1;
  SQLLEN row_count;
  SQLSMALLINT  len;

  const string DIAGNOSTICS_W_TABLE = "DIAGNOSTICS_TABLE_W_1";

  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(DIAGNOSTICS_W_TABLE, {{"id", "INT"}}));

  string query = InsertStatement(DIAGNOSTICS_W_TABLE, "(1)");

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_TRUE(odbcHandler.IsSqlSuccess(rcode)) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  rcode = SQLGetDiagField(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle(), 0, SQL_DIAG_ROW_COUNT, &row_count, 0, &len);
  ASSERT_TRUE(odbcHandler.IsSqlSuccess(rcode)) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_EQ(row_count, 1);
}

TEST_F(Diagnostics, SQLGetDiagField_UnsuccessfulStatement) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER rec_num = 1;
  SQLCHAR      info[256];
  SQLSMALLINT  len;
  string query = "SELECT ORDER BY INCORRECT SYNTAX";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);
  
  rcode = SQLGetDiagField(SQL_HANDLE_STMT, odbcHandler.GetStatementHandle(), rec_num, SQL_DIAG_SQLSTATE, info, sizeof(info), &len);
  ASSERT_TRUE(odbcHandler.IsSqlSuccess(rcode)) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  ASSERT_STREQ((const char*) info, "42000");
}

TEST_F(Diagnostics, SQLGetDiagField_Error) {
  OdbcHandler odbcHandler;
  RETCODE rcode;
  SQLINTEGER rec_num = 1;
  SQLCHAR      info[256];
  SQLSMALLINT  len;

  const string DIAGNOSTICS_RO_TABLE = "DIAGNOSTICS_TABLE_RO_1";
  string query = SelectStatement(DIAGNOSTICS_RO_TABLE, { "*" });
  
  DatabaseObjects dbObjects;
  ASSERT_NO_FATAL_FAILURE(dbObjects.CreateTable(DIAGNOSTICS_RO_TABLE, {{"id", "INT"}}));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) query.c_str(), SQL_NTS);
  ASSERT_TRUE(odbcHandler.IsSqlSuccess(rcode)) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);

  // The handle passed should be a statement handle when the field is SQL_DIAG_DYNAMIC_FUNCTION
  rcode = SQLGetDiagField(SQL_HANDLE_DBC, odbcHandler.GetConnectionHandle(), rec_num, SQL_DIAG_DYNAMIC_FUNCTION, info, sizeof(info), &len);
  ASSERT_EQ(rcode, SQL_ERROR);
}
