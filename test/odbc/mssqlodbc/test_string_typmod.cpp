#include "../src/odbc_handler.h"
#include "../src/drivers.h"

#include <gtest/gtest.h>
#include <sqlext.h>

#include <string>
#include <tuple>
#include <vector>

using std::string;
using std::tuple;
using std::vector;

// Column metadata of string expressions must report the length SQL Server
// would report, not VARCHAR(MAX). PostgreSQL drops the typmod of function
// results and most expressions, so the TDS layer derives it.
class MSSQL_String_Typmod : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }
    OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
    odbcHandler.ConnectAndExecQuery(
      "CREATE TABLE odbc_string_typmod_t (v10 VARCHAR(10), v20 VARCHAR(20), v30 VARCHAR(30), "
      "n15 NVARCHAR(15), vmax VARCHAR(MAX))");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery("INSERT INTO odbc_string_typmod_t VALUES ('a', 'b', 'c', N'd', 'e')");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(
      "CREATE FUNCTION odbc_string_typmod_f (@p VARCHAR(100)) RETURNS VARCHAR(25) AS BEGIN RETURN LEFT(@p, 25) END");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(
      "CREATE FUNCTION odbc_string_typmod_nf (@p NVARCHAR(100)) RETURNS NVARCHAR(40) AS BEGIN RETURN @p END");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(
      "CREATE FUNCTION odbc_string_typmod_long () RETURNS VARCHAR(5) AS BEGIN RETURN 'abcdefgh' END");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(
      "CREATE FUNCTION odbc_string_typmod_nlong () RETURNS NVARCHAR(3) AS BEGIN RETURN N'abcdef' END");
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      return;
    }
    OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
    odbcHandler.ConnectAndExecQuery("DROP FUNCTION IF EXISTS odbc_string_typmod_f");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery("DROP FUNCTION IF EXISTS odbc_string_typmod_nf");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery("DROP FUNCTION IF EXISTS odbc_string_typmod_long");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery("DROP FUNCTION IF EXISTS odbc_string_typmod_nlong");
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery("DROP TABLE IF EXISTS odbc_string_typmod_t");
  }
};

// query, expected SQL type, expected column size
static void CheckColumnSize(const string &query, SQLSMALLINT expected_type, SQLULEN expected_size) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  SQLCHAR col_name[256];
  SQLSMALLINT name_length, data_type, dec_digits, nullable;
  SQLULEN col_size;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(query));
  RETCODE rcode = SQLDescribeCol(odbcHandler.GetStatementHandle(), 1, col_name, sizeof(col_name),
                                 &name_length, &data_type, &col_size, &dec_digits, &nullable);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(data_type, expected_type) << query;
  EXPECT_EQ(col_size, expected_size) << query;
  // the row must also be sent: the derived length may not be shorter than the data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_TRUE(rcode == SQL_SUCCESS || rcode == SQL_NO_DATA) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

TEST_F(MSSQL_String_Typmod, ScalarUdfReturnsDeclaredLength) {
  CheckColumnSize("SELECT dbo.odbc_string_typmod_f(v30) FROM odbc_string_typmod_t", SQL_VARCHAR, 25);
  CheckColumnSize("SELECT dbo.odbc_string_typmod_nf(n15) FROM odbc_string_typmod_t", SQL_WVARCHAR, 40);
}

TEST_F(MSSQL_String_Typmod, StringLiteral) {
  CheckColumnSize("SELECT 'abcd'", SQL_VARCHAR, 4);
}

// Characters outside the BMP take two UTF-16 code units on the wire. A length
// derived from a literal must count them, or sending the row fails.
TEST_F(MSSQL_String_Typmod, LiteralOutsideBmp) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  SQLCHAR col_name[256];
  SQLSMALLINT name_length, data_type, dec_digits, nullable;
  SQLULEN col_size;
  // SELECT quotename('x<U+1F680><U+1F31F>') sent as UTF-16 so the driver does not convert it
  const char16_t query[] = u"SELECT quotename('x\U0001F680\U0001F31F')";

  ASSERT_NO_FATAL_FAILURE(odbcHandler.Connect(true));
  RETCODE rcode = SQLExecDirectW(odbcHandler.GetStatementHandle(), (SQLWCHAR *) query, SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLDescribeCol(odbcHandler.GetStatementHandle(), 1, col_name, sizeof(col_name),
                         &name_length, &data_type, &col_size, &dec_digits, &nullable);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(data_type, SQL_WVARCHAR);
  EXPECT_EQ(col_size, 7);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
}

TEST_F(MSSQL_String_Typmod, Concatenation) {
  CheckColumnSize("SELECT v10 + v20 FROM odbc_string_typmod_t", SQL_VARCHAR, 30);
  CheckColumnSize("SELECT v10 + '-' + v20 FROM odbc_string_typmod_t", SQL_VARCHAR, 31);
  CheckColumnSize("SELECT CONCAT(v10, v20) FROM odbc_string_typmod_t", SQL_VARCHAR, 30);
}

TEST_F(MSSQL_String_Typmod, BoundedByInput) {
  CheckColumnSize("SELECT LEFT(v30, 5) FROM odbc_string_typmod_t", SQL_VARCHAR, 5);
  CheckColumnSize("SELECT SUBSTRING(v30, 2, 7) FROM odbc_string_typmod_t", SQL_VARCHAR, 7);
  CheckColumnSize("SELECT LTRIM(RTRIM(v20)) FROM odbc_string_typmod_t", SQL_VARCHAR, 20);
  CheckColumnSize("SELECT UPPER(v10) FROM odbc_string_typmod_t", SQL_VARCHAR, 10);
}

TEST_F(MSSQL_String_Typmod, IsNullUsesFirstArgument) {
  CheckColumnSize("SELECT ISNULL(v10, v30) FROM odbc_string_typmod_t", SQL_VARCHAR, 10);
}

TEST_F(MSSQL_String_Typmod, LongestArm) {
  CheckColumnSize("SELECT COALESCE(v10, v20) FROM odbc_string_typmod_t", SQL_VARCHAR, 20);
  CheckColumnSize("SELECT CASE WHEN v10 = 'a' THEN v10 ELSE v30 END FROM odbc_string_typmod_t", SQL_VARCHAR, 30);
  CheckColumnSize("SELECT CASE WHEN v10 = 'a' THEN v20 ELSE NULL END FROM odbc_string_typmod_t", SQL_VARCHAR, 20);
  CheckColumnSize("SELECT v10 FROM odbc_string_typmod_t UNION ALL SELECT v30 FROM odbc_string_typmod_t",
                  SQL_VARCHAR, 30);
}

TEST_F(MSSQL_String_Typmod, Aggregates) {
  CheckColumnSize("SELECT MAX(v20) FROM odbc_string_typmod_t", SQL_VARCHAR, 20);
  CheckColumnSize("SELECT x FROM (SELECT MIN(v10) AS x FROM odbc_string_typmod_t) s", SQL_VARCHAR, 10);
}

TEST_F(MSSQL_String_Typmod, ReplaceIs8000) {
  CheckColumnSize("SELECT REPLACE(v10, 'a', 'b') FROM odbc_string_typmod_t", SQL_VARCHAR, 8000);
}

TEST_F(MSSQL_String_Typmod, UnknownStaysMax) {
  // varchar(max) input and lengths above 8000 keep reporting MAX
  CheckColumnSize("SELECT vmax FROM odbc_string_typmod_t", SQL_VARCHAR, 0);
  CheckColumnSize("SELECT v10 + vmax FROM odbc_string_typmod_t", SQL_VARCHAR, 0);
  CheckColumnSize("SELECT ISNULL(vmax, v10) FROM odbc_string_typmod_t", SQL_VARCHAR, 0);
}

static void CheckValue(const string &query, SQLULEN expected_size, const string &expected_value) {
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  SQLCHAR col_name[256];
  SQLSMALLINT name_length, data_type, dec_digits, nullable;
  SQLULEN col_size;
  char value[256];
  SQLLEN indicator;

  ASSERT_NO_FATAL_FAILURE(odbcHandler.ConnectAndExecQuery(query));
  RETCODE rcode = SQLDescribeCol(odbcHandler.GetStatementHandle(), 1, col_name, sizeof(col_name),
                                 &name_length, &data_type, &col_size, &dec_digits, &nullable);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(col_size, expected_size) << query;
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  rcode = SQLGetData(odbcHandler.GetStatementHandle(), 1, SQL_C_CHAR, value, sizeof(value), &indicator);
  ASSERT_EQ(rcode, SQL_SUCCESS) << odbcHandler.GetErrorMessage(SQL_HANDLE_STMT, rcode);
  EXPECT_EQ(string(value), expected_value) << query;
}

// A value longer than the derived length is clipped to it, like SQL Server
// does when converting to the declared type, instead of failing the row.
TEST_F(MSSQL_String_Typmod, LongerValueIsClipped) {
  CheckValue("SELECT dbo.odbc_string_typmod_long()", 5, "abcde");
  CheckValue("SELECT dbo.odbc_string_typmod_nlong()", 3, "abc");
}
