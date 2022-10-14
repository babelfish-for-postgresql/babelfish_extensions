#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "../src/drivers.h"
#include <cmath>
#include <iostream>
#include <regex>
using std::pair;

const string BBF_TABLE_NAME = "master.dbo.date_table_odbc_test";
const string BBF_VIEW_NAME = "master.dbo.date_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.date_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.date_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "date";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;
const int BUFFER_SIZE = 256;
const int INT_BYTES_EXPECTED = 4;
const int DATE_BYTES_EXPECTED = 10;

class PSQL_DataTypes_Date : public testing::Test {
  void SetUp() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));

    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }

  void TearDown() override {
    if (!Drivers::DriverExists(ServerType::PSQL)) {
      GTEST_SKIP() << "PSQL Driver not present: skipping all tests for this fixture.";
    }
    if (!Drivers::DriverExists(ServerType::MSSQL)) {
      GTEST_SKIP() << "MSSQL Driver not present: skipping all tests for this fixture.";
    }

    OdbcHandler bbf_test_setup(Drivers::GetDriver(ServerType::MSSQL));
    // Attempting to drop view causes query to fail
    // ERROR: was not able to run query: DROP VIEW IF EXISTS master.dbo.date_view_odbc_test
    // Return code was: -1
    // SQL Status of: 00000
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    // bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    // bbf_test_setup.CloseStmt();
    // bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    pg_test_setup.CloseStmt();
    pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_Date, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const int LENGTH_EXPECTED = 10;
  const int PRECISION_EXPECTED = 0;
  const int SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "date";

  char name[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;

  RETCODE rcode;
  OdbcHandler BBF_obdcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  // Create a table with columns defined with the specific datatype being tested.
  BBF_obdcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_obdcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  BBF_obdcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure column attributes are correct
  rcode = SQLColAttribute(BBF_obdcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&length);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, LENGTH_EXPECTED);

  rcode = SQLColAttribute(BBF_obdcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&precision);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PRECISION_EXPECTED);

  rcode = SQLColAttribute(BBF_obdcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&scale);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, SCALE_EXPECTED);

  rcode = SQLColAttribute(BBF_obdcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_TYPE_NAME, // Get the type name of the column
                          name,
                          BUFFER_SIZE,
                          NULL,
                          NULL);
  ASSERT_EQ(string(name), NAME_EXPECTED);

  rcode = SQLFetch(BBF_obdcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Connect with PG to ensure table made with BBF connection exists
  PG_odbcHandler.Connect(true);

  // Select * From Table to ensure that it exists
  PG_odbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure column attributes are correct
  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&length);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, LENGTH_EXPECTED);

  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&precision);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PRECISION_EXPECTED);

  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&scale);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, SCALE_EXPECTED);

  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_TYPE_NAME, // Get the type name of the column
                          name,
                          BUFFER_SIZE,
                          NULL,
                          NULL);
  ASSERT_EQ(string(name), NAME_EXPECTED);

  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  PG_odbcHandler.CloseStmt();
  PG_odbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Date, Insertion_Success) {
  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_obdcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "NULL",        // Null
    "2000-01-19",  // Rand
    "0001-01-01",  // Min
    "9999-12-03"   // Max
  };
  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    const string INSERT_VALUE = VALID_INSERTED_VALUES[i] != "NULL" ? "\'" + VALID_INSERTED_VALUES[i] + "\'" : VALID_INSERTED_VALUES[i];
    insert_string += comma + "(" + std::to_string(i) + "," + INSERT_VALUE + ")";
    comma = ",";
  }

  BBF_obdcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_obdcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_obdcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));

  rcode = SQLRowCount(BBF_obdcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  BBF_obdcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_obdcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_obdcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_obdcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, DATE_BYTES_EXPECTED);
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_obdcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_obdcHandler.CloseStmt();

  // Connect via PG to ensure data is the same
  PG_odbcHandler.Connect(true);

  // Insert same data with PG
  insert_string = "";
  comma = "";
  for (int i = NUM_OF_INSERTS; i < 2 * NUM_OF_INSERTS; i++) {
    const string INSERT_VALUE = VALID_INSERTED_VALUES[i % NUM_OF_INSERTS] != "NULL" ? 
                                "\'" + VALID_INSERTED_VALUES[i % NUM_OF_INSERTS] + "\'" : 
                                VALID_INSERTED_VALUES[i % NUM_OF_INSERTS];
    insert_string += comma + "(" + std::to_string(i) + "," + INSERT_VALUE + ")";
    comma = ",";
  }

  // Insert valid values into the table and assert affected rows
  PG_odbcHandler.ExecQuery(InsertStatement(PG_TABLE_NAME, insert_string));

  rcode = SQLRowCount(PG_odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  PG_odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  PG_odbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(PG_odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < 2 * NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(PG_odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i % NUM_OF_INSERTS] != "NULL") {
      ASSERT_EQ(data_len, DATE_BYTES_EXPECTED);
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i % NUM_OF_INSERTS]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Check PG inserted values in BBF
  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_obdcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_obdcHandler.BindColumns(BIND_COLUMNS));

  for (int i = NUM_OF_INSERTS; i < 2 * NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_obdcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i % NUM_OF_INSERTS] != "NULL") {
      ASSERT_EQ(data_len, DATE_BYTES_EXPECTED);
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i % NUM_OF_INSERTS]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_obdcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Clean up by dropping tables
  BBF_obdcHandler.CloseStmt();
  BBF_obdcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Date, Insertion_Fail) {
  RETCODE rcode;
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<string> INVALID_INSERTED_VALUES = {
    "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",   // Not Hex values
    "00000000-0000-0000-0000-00000000000",    // Too short
    "00000000-0000-0000-0000-0000000000000",  // Too long
    "00000000:0000:0000:0000:000000000000",   // Wrong format
    "00000000-0000-0000-0000-00000000000X",   // Invalid Character
    "123456789"                               // Wrong format, No casting
  };
  const int NUM_OF_INSERTS = INVALID_INSERTED_VALUES.size();

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Attempt to insert values that are out of range and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    string insert_string = "(" + std::to_string(i) + "," + INVALID_INSERTED_VALUES[i] + ")";

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the tables and assert that nothing was inserted
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}
