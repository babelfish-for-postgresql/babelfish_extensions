#include <gtest/gtest.h>
#include <sqlext.h>
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "../src/drivers.h"
#include <iostream>
using std::pair;

const string BBF_TABLE_NAME = "master.dbo.time_table_odbc_test";
// For BBF Connection
//   Cannot prepend database name when creating/dropping view
//   Must prepend database name when selecting from view
const string BBF_VIEW_NAME = "dbo.time_view_odbc_test";
const string PG_TABLE_NAME = "master_dbo.time_table_odbc_test";
const string PG_VIEW_NAME = "master_dbo.time_view_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "time";
const vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;
const int BUFFER_SIZE = 256;
const int INT_BYTES_EXPECTED = 4;
// Depends on scale & connection
// BBF will use all bytes as it pads with 0s
// PG will return only necesaary bytes
const int TIME_BYTES_EXPECTED = 16;

class PSQL_DataTypes_Time : public testing::Test {
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
    bbf_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", BBF_VIEW_NAME));
    bbf_test_setup.CloseStmt();
    bbf_test_setup.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
    
    OdbcHandler pg_test_setup(Drivers::GetDriver(ServerType::PSQL));
    pg_test_setup.ConnectAndExecQuery(DropObjectStatement("VIEW", PG_VIEW_NAME));
    pg_test_setup.CloseStmt();
    pg_test_setup.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
  }
};

string getExpectedData(const string &input) {
  string ret = string(input);
  if (strcmp(input.data(), "NULL") == 0) {
    return ret;
  }

  size_t period_pos = ret.find('.');
  if (period_pos == std::string::npos) {
    ret.append(".");
  }
  unsigned int padding = TIME_BYTES_EXPECTED - ret.length();
  ret.append(string(padding, '0'));
  return ret;
}

TEST_F(PSQL_DataTypes_Time, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const int BBF_LENGTH_EXPECTED = 16;
  const int BBF_PRECISION_EXPECTED = 7;
  const int BBF_SCALE_EXPECTED = 7;
  const int PG_LENGTH_EXPECTED = 8;  
  const int PG_PRECISION_EXPECTED = 6;  
  const int PG_SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "time";

  char name[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;

  RETCODE rcode;
  OdbcHandler BBF_odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  // Create a table with columns defined with the specific datatype being tested.
  BBF_odbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure column attributes are correct
  rcode = SQLColAttribute(BBF_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&length);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, BBF_LENGTH_EXPECTED);

  rcode = SQLColAttribute(BBF_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&precision);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, BBF_PRECISION_EXPECTED);

  rcode = SQLColAttribute(BBF_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&scale);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, BBF_SCALE_EXPECTED);

  rcode = SQLColAttribute(BBF_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_TYPE_NAME, // Get the type name of the column
                          name,
                          BUFFER_SIZE,
                          NULL,
                          NULL);
  ASSERT_EQ(string(name), NAME_EXPECTED);

  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
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
  ASSERT_EQ(length, PG_LENGTH_EXPECTED);

  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&precision);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PG_PRECISION_EXPECTED);

  rcode = SQLColAttribute(PG_odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&scale);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, PG_SCALE_EXPECTED);

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

// BBF 
//    Supports 7th digit fractional second
//    pads fractional seconds with 0s
//    Length is always 16 (due to padding)
// PG 
//    Rounds 7th digit fractional second
//    does NOT pad
//    length is dynamic due to not having automatic padding
TEST_F(PSQL_DataTypes_Time, Insertion_Success) {
  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<string> VALID_INSERTED_VALUES = {
    "NULL",
    "00:00:00",         // Min
    "12:34:56",
    "23:59:59.1",
    "23:59:59.22",
    "23:59:59.333",
    "23:59:59.4444",
    "23:59:59.55555",
    "23:59:59.666666",
    // BBF Supports fractional seconds to 7 places
    // PG Rounds up the 7th digit
    // "23:59:59.7777777",  // Max
  };
  const int NUM_OF_INSERTS = VALID_INSERTED_VALUES.size();

  vector<string> expected_data = {};
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    expected_data.push_back(getExpectedData(VALID_INSERTED_VALUES[i]));
  }

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

  BBF_odbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  BBF_odbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, insert_string));

  rcode = SQLRowCount(BBF_odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  BBF_odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, TIME_BYTES_EXPECTED);
      ASSERT_EQ(data, expected_data[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_odbcHandler.CloseStmt();

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
      ASSERT_EQ(data_len, VALID_INSERTED_VALUES[i % NUM_OF_INSERTS].length());
      ASSERT_EQ(data, VALID_INSERTED_VALUES[i % NUM_OF_INSERTS]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  PG_odbcHandler.CloseStmt();

  // Check PG inserted values in BBF
  // Select all from the tables and assert that the following attributes of the type is correct:
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(BBF_odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < 2 * NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (VALID_INSERTED_VALUES[i % NUM_OF_INSERTS] != "NULL") {
      ASSERT_EQ(data_len, TIME_BYTES_EXPECTED);
      ASSERT_EQ(data, expected_data[i % NUM_OF_INSERTS]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_odbcHandler.CloseStmt();

  // Clean up by dropping tables
  BBF_odbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  PG_odbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

TEST_F(PSQL_DataTypes_Time, Insertion_Fail) {
  RETCODE rcode;
  OdbcHandler BBF_odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<string> INVALID_INSERTED_VALUES = {
    "24:00:0",    // Hour over range
    "00:60:0",    // Minute over range
    "00:00:60",   // Second over range
    "00-00-00",   // Format hh-mm-ss

    // ODBC API format for Time is hh:mm:ss
    // Below are valid in SQL Server
    "00:00:00.00 AM"
    "00AM"
    "00 AM"
  };
  const int NUM_OF_INSERTS = INVALID_INSERTED_VALUES.size();

  BBF_odbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_odbcHandler.CloseStmt();

  // Attempt to insert values that are out of range and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    string insert_string = "(" + std::to_string(i) + "," + INVALID_INSERTED_VALUES[i] + ")";

    rcode = SQLExecDirect(BBF_odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(BBF_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the tables and assert that nothing was inserted
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_odbcHandler.CloseStmt();

  // Try with PG
  PG_odbcHandler.Connect(true);
  // Attempt to insert values that are out of range and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    string insert_string = "(" + std::to_string(i) + "," + INVALID_INSERTED_VALUES[i] + ")";

    rcode = SQLExecDirect(PG_odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(PG_TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the tables and assert that nothing was inserted
  PG_odbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  PG_odbcHandler.CloseStmt();

  BBF_odbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  PG_odbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}

// Disabled as it cannot select updated values in PG Connection
TEST_F(PSQL_DataTypes_Time, Update_Success) {
  const string PK_INSERTED = "0";
  const string DATA_INSERTED = "00:00:00";
  const string DATA_EXPECTED = getExpectedData(DATA_INSERTED);

  const vector <string> DATA_UPDATED_VALUES = {
    "23:59:59",
    "12:34:56",
    "00:00:00"
  };
  const int NUM_OF_DATA = DATA_UPDATED_VALUES.size();

  vector<string> expected_data = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_data.push_back(getExpectedData(DATA_UPDATED_VALUES[i]));
  }

  const string INSERT_STRING = "(" + PK_INSERTED + ",\'" + DATA_INSERTED + "\')";
  const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + PK_INSERTED;

  const int AFFECTED_ROWS_EXPECTED = 1;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler BBF_odbcHandler(Drivers::GetDriver(ServerType::MSSQL));
  OdbcHandler PG_odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  vector<pair<string, string>> update_col{};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    const string INSERT_VALUE = DATA_UPDATED_VALUES[i] != "NULL" ? "\'" + DATA_UPDATED_VALUES[i] + "\'" : DATA_UPDATED_VALUES[i];
    update_col.push_back(pair<string, string>(COL2_NAME, INSERT_VALUE));
  }

  BBF_odbcHandler.ConnectAndExecQuery(CreateTableStatement(BBF_TABLE_NAME, TABLE_COLUMNS));
  BBF_odbcHandler.CloseStmt();

  // Insert valid values into the table using the correct ODBC data type mapping.
  BBF_odbcHandler.ExecQuery(InsertStatement(BBF_TABLE_NAME, INSERT_STRING));
  BBF_odbcHandler.CloseStmt();

  // Bind Columns
  ASSERT_NO_FATAL_FAILURE(BBF_odbcHandler.BindColumns(BIND_COLUMNS));

  // Assert that value is inserted properly
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
  ASSERT_EQ(pk, atoi(PK_INSERTED.c_str()));
  ASSERT_EQ(data_len, TIME_BYTES_EXPECTED);
  ASSERT_EQ(data, DATA_EXPECTED);

  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_odbcHandler.CloseStmt();

  // Update value multiple times
  for (int i = 0; i < NUM_OF_DATA; i++) {
    BBF_odbcHandler.ExecQuery(UpdateTableStatement(BBF_TABLE_NAME, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(BBF_odbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    BBF_odbcHandler.CloseStmt();

    // Assert that updated value is present
    BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
    rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());

    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, atoi(PK_INSERTED.c_str()));
    if (DATA_UPDATED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, TIME_BYTES_EXPECTED);
      ASSERT_EQ(data, expected_data[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }

    rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    BBF_odbcHandler.CloseStmt();
  }
  
  // Try on PG Connection
  PG_odbcHandler.Connect(true);
  ASSERT_NO_FATAL_FAILURE(PG_odbcHandler.BindColumns(BIND_COLUMNS));

  PG_odbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
  ASSERT_EQ(pk, atoi(PK_INSERTED.c_str()));
  ASSERT_EQ(data_len, DATA_INSERTED.length());
  ASSERT_EQ(data, DATA_INSERTED);

  rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  PG_odbcHandler.CloseStmt();

  // Update value multiple times
  for (int i = 0; i < NUM_OF_DATA; i++) {
    PG_odbcHandler.ExecQuery(UpdateTableStatement(PG_TABLE_NAME, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(PG_odbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    PG_odbcHandler.CloseStmt();

    // Assert that updated value is present
    PG_odbcHandler.ExecQuery(SelectStatement(PG_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
    rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());

    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
    ASSERT_EQ(pk, atoi(PK_INSERTED.c_str()));
    if (DATA_UPDATED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, DATA_UPDATED_VALUES[i].length());
      ASSERT_EQ(data, DATA_UPDATED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }

    rcode = SQLFetch(PG_odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    PG_odbcHandler.CloseStmt();
  }

  // Ensure update is seen on BBF side as well
  BBF_odbcHandler.ExecQuery(SelectStatement(BBF_TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, INT_BYTES_EXPECTED);
  ASSERT_EQ(pk, atoi(PK_INSERTED.c_str()));
  ASSERT_EQ(data_len, TIME_BYTES_EXPECTED);
  ASSERT_EQ(data, DATA_EXPECTED);

  rcode = SQLFetch(BBF_odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  BBF_odbcHandler.CloseStmt();

  // Clean up
  BBF_odbcHandler.ExecQuery(DropObjectStatement("TABLE", BBF_TABLE_NAME));
  PG_odbcHandler.ExecQuery(DropObjectStatement("TABLE", PG_TABLE_NAME));
}
