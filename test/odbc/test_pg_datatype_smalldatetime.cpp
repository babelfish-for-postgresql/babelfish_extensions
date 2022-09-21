#include <gtest/gtest.h>
#include <sqlext.h>
#include "odbc_handler.h"
#include "query_generator.h"
#include <cmath>
#include <iostream>
#include <time.h>
using std::pair;

const string TABLE_NAME = "master_dbo.smalldatetime_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.smalldatetime";
const string VIEW_NAME = "master_dbo.smalldatetime_view_odbc_test";
vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;
const int BUFFER_SIZE = 256;

class PSQL_DataTypes_SmallDateTime : public testing::Test {
  void SetUp() override {
    OdbcHandler test_setup;
    test_setup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }

  void TearDown() override {
    OdbcHandler test_teardown;
    test_teardown.ConnectAndExecQuery(DropObjectStatement("VIEW", VIEW_NAME));
    test_teardown.CloseStmt();
    test_teardown.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const int LENGTH_EXPECTED = 255;        // Double check
  const int PRECISION_EXPECTED = 0;       // Double check
  const int SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "unknown"; // Double check, Expected "smalldatetime"?

  char name[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  // Create a table with columns defined with the specific datatype being tested.
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure column attributes are correct
  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&length);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, LENGTH_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&precision);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PRECISION_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN *)&scale);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, SCALE_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_TYPE_NAME, // Get the type name of the column
                          name,
                          BUFFER_SIZE,
                          NULL,
                          NULL);
  ASSERT_EQ(string(name), NAME_EXPECTED);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Insertion_Success) {
  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                           // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL",
    "1900-01-01 00:00:00",        // Default Value
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };
  const int NUM_OF_INSERTS = EXPECTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + ",";
    if (INSERTED_VALUES[i] != "NULL") {
      insert_string += "\'" + INSERTED_VALUES[i] + "\'";
    }
    else {
      insert_string += INSERTED_VALUES[i];
    }
    insert_string += ")";
    comma = ",";
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, EXPECTED_VALUES[i].length());
      ASSERT_EQ(string(data), EXPECTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Insertion_Fail) {
  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INVALID_INSERTED_VALUES = {
    "01-01-2000",                 // Format
    "December 31, 1900 CE",
    "2080-01-01 00:00:00",        // Year
    "1899-12-31 00:00:00",
    "0000-01-01 00:00:00",
    "1900-32-01 00:00:00",        // Month
    "1900-00-01 00:00:00",
    "1900-01-32 00:00:00",        // Day
    "1900-01-00 00:00:00",
    "1900-02-31 00:00:00",        // Feb 31st
    "0001-01-01 24:00:00", 	      // Hour
    "0001-01-01 00:60:00",        // Minutes
    "0001-01-01 00:00:60", 	      // Seconds
    "0001-01-01 00:00:60000", 	  // Milliseconds
    "2079-06-06 23:59:39"         // Rounding up over range
  };
  const int NUM_OF_INSERTS = INVALID_INSERTED_VALUES.size();

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Attempt to insert values that are out of range and assert that they all fail
  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    string insert_string = "(" + std::to_string(i) + ",\'" + INVALID_INSERTED_VALUES[i] + "\')";

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the tables and assert that nothing was inserted
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Update_Success) {
  const int PK_INSERTED = 1;
  const string DATA_INSERTED = "1900-01-01 00:00:00";

  const vector<string> DATA_UPDATED_VALUES = {
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };
  const int NUM_OF_DATA = EXPECTED_VALUES.size();

  const string INSERT_STRING = "(" + std::to_string(PK_INSERTED) + ",\'" + DATA_INSERTED + "\')";
  const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + std::to_string(PK_INSERTED);

  const int PK_BYTES_EXPECTED = 4;
  const int AFFECTED_ROWS_EXPECTED = 1;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  vector<pair<string, string>> update_col{};

  for (int i = 0; i < NUM_OF_DATA; i++) {
    update_col.push_back(pair<string, string>(COL2_NAME, "\'" + DATA_UPDATED_VALUES[i] + "\'"));
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table using the correct ODBC data type mapping.
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, INSERT_STRING));
  odbcHandler.CloseStmt();

  // Bind Columns
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  // Assert that value is inserted properly
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
  ASSERT_EQ(pk, PK_INSERTED);
  ASSERT_EQ(data_len, DATA_INSERTED.length());
  ASSERT_EQ(string(data), DATA_INSERTED);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  // Update value multiple times
  for (int i = 0; i < NUM_OF_DATA; i++) {
    odbcHandler.ExecQuery(UpdateTableStatement(TABLE_NAME, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    // Assert that updated value is present
    odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, PK_INSERTED);
    ASSERT_EQ(data_len, EXPECTED_VALUES[i].length());
    ASSERT_EQ(string(data), EXPECTED_VALUES[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Update_Fail) {
  const int PK_INSERTED = 1;
  const string DATA_INSERTED = "1900-01-01 00:00:00";
  const string DATA_UPDATED_VALUE = "1900-02-31 00:00:00"; // Feb 31st

  const string INSERT_STRING = "(" + std::to_string(PK_INSERTED) + ",\'" + DATA_INSERTED + "\')";
  const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + std::to_string(PK_INSERTED);

  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  vector<pair<string, string>> update_col = {
    {COL2_NAME, "\'" + DATA_UPDATED_VALUE + "\'"}
  };

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table using the correct ODBC data type mapping.
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, INSERT_STRING));
  odbcHandler.CloseStmt();

  // Bind Columns
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  // Assert that value is inserted properly
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
  ASSERT_EQ(pk, PK_INSERTED);
  ASSERT_EQ(data_len, DATA_INSERTED.length());
  ASSERT_EQ(string(data), DATA_INSERTED);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  // Update value and assert an error is present
  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)UpdateTableStatement(TABLE_NAME, update_col, UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);
  odbcHandler.CloseStmt();

  // Assert that no values changed
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());

  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
  ASSERT_EQ(pk, PK_INSERTED);
  ASSERT_EQ(data_len, DATA_INSERTED.length());
  ASSERT_EQ(string(data), DATA_INSERTED);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Comparison_Operators) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  RETCODE rcode;
  OdbcHandler odbcHandler;
  SQLLEN affected_rows;
  const int BYTES_EXPECTED = 1;

  vector<string> INSERTED_PK = {
    "1900-01-01 00:00:00",
    "2000-01-01 00:00:00"
  };

  vector<string> INSERTED_DATA = {
    "1900-12-31 23:59:00",
    "2000-01-01 00:00:00"
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  vector<string> OPERATIONS_QUERY = {
    COL1_NAME + "=" + COL2_NAME,
    COL1_NAME + "<>" + COL2_NAME,
    COL1_NAME + "<" + COL2_NAME,
    COL1_NAME + "<=" + COL2_NAME,
    COL1_NAME + ">" + COL2_NAME,
    COL1_NAME + ">=" + COL2_NAME
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<vector<char>> expected_results = {};
  for (int i = 0; i < NUM_OF_DATA; i++) {
    expected_results.push_back({});
    const char *date_1 = INSERTED_PK[i].data();
    const char *date_2 = INSERTED_DATA[i].data();
    expected_results[i].push_back(strcmp(date_1, date_2) == 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) != 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) < 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) <= 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) > 0 ? '1' : '0');
    expected_results[i].push_back(strcmp(date_1, date_2) >= 0 ? '1' : '0');
  }

  char col_results[NUM_OF_OPERATIONS];
  SQLLEN col_len[NUM_OF_OPERATIONS];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&col_results[i], BUFFER_SIZE, &col_len[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  string insert_string{};
  string comma{};

  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insert_string += comma + "(\'" + INSERTED_PK[i] + "\',\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_DATA; i++) {
    odbcHandler.CloseStmt();
    odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, OPERATIONS_QUERY, vector<string>{}, COL1_NAME + "=\'" + INSERTED_PK[i] + "\'"));
    ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      ASSERT_EQ(col_len[j], BYTES_EXPECTED);
      ASSERT_EQ(col_results[j], expected_results[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Comparison_Functions) {
  const int BYTES_EXPECTED = 1;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INSERTED_DATA = {
    "1900-01-01 00:00:00",
    "1950-12-31 00:00:00",
    "2000-01-19 00:00:00",
  };
  const int NUM_OF_DATA = INSERTED_DATA.size();

  const vector<string> OPERATIONS_QUERY = {
    "MIN(" + COL2_NAME + ")",
    "MAX(" + COL2_NAME + ")"
  };
  const int NUM_OF_OPERATIONS = OPERATIONS_QUERY.size();

  // initialization of expected_results
  vector<string> expected_results = {};
  int min_expected = 0, max_expected = 0;
  for (int i = 1; i < NUM_OF_DATA; i++) {
    const char *currMin = INSERTED_DATA[min_expected].data();
    const char *currMax = INSERTED_DATA[max_expected].data();
    const char *curr = INSERTED_DATA[i].data();

    min_expected = strcmp(curr, currMin) < 0 ? i : min_expected;
    max_expected = strcmp(curr, currMax) > 0 ? i : min_expected;
  }
  expected_results.push_back(INSERTED_DATA[min_expected]);
  expected_results.push_back(INSERTED_DATA[max_expected]);

  char col_results[NUM_OF_OPERATIONS][BUFFER_SIZE];
  SQLLEN col_len[NUM_OF_OPERATIONS];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&col_results[i], BUFFER_SIZE, &col_len[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  string insert_string{};
  string comma{};

  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insert_string += comma + "(" + std::to_string(i) + ",\'" + INSERTED_DATA[i] + "\')";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, OPERATIONS_QUERY, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    ASSERT_EQ(col_len[i], expected_results[i].length());
    ASSERT_EQ(string(col_results[i]), expected_results[i]);
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, View_Creation) {
  const string VIEW_QUERY = "SELECT * FROM " + TABLE_NAME;
  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INSERTED_VALUES = {
    "NULL",
    "",                           // Default Value
    "1900-01-01",
    "2079-06-06",
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:29",        // Max
    "2079-06-05 23:59:29",        // Round Down
    "1900-01-01 23:59:59",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };

  const vector<string> EXPECTED_VALUES = {
    "NULL",
    "1900-01-01 00:00:00",        // Default Value
    "1900-01-01 00:00:00",
    "2079-06-06 00:00:00",        
    "1900-01-01 00:00:00",        // Min
    "2079-06-06 23:59:00",        // Max
    "2079-06-05 23:59:00",        // Round Down
    "1900-01-02 00:00:00",        // Round Up
    "2000-01-01 12:30:00"         // Random
  };
  const int NUM_OF_INSERTS = EXPECTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    insert_string += comma + "(" + std::to_string(i) + ",";
    if (INSERTED_VALUES[i] != "NULL") {
      insert_string += "\'" + INSERTED_VALUES[i] + "\'";
    }
    else {
      insert_string += INSERTED_VALUES[i];
    }
    insert_string += ")";
    comma = ",";
  }

  // Create Table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTS);

  odbcHandler.CloseStmt();

  // Create view
  odbcHandler.ExecQuery(CreateViewStatement(VIEW_NAME, VIEW_QUERY));
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(VIEW_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTS; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);

    if (INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, EXPECTED_VALUES[i].length());
      ASSERT_EQ(string(data), EXPECTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }      
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("VIEW", VIEW_NAME));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Unique_Constraints) {
  const vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME + " UNIQUE"}
  };
  const string UNIQUE_COLUMN_NAME = COL2_NAME;

  const int PK_BYTES_EXPECTED = 4;
  const int DATA_BYTES_EXPECTED = 1;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00",
    "2000-12-31 00:00:00"
  };
  const int NUM_OF_INSERTED = INSERTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  string insert_string{};
  string comma{};

  for (int i = 0; i < NUM_OF_INSERTED; i++) {
    insert_string += comma + "(" + std::to_string(i) + ",\'" + INSERTED_VALUES[i] + "\')";
    comma = ",";
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Check if unique constraint still matches after creation
  char column_name[BUFFER_SIZE];
  char type_name[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int>> TABLE_BIND_COLUMNS = {
    {1, SQL_C_CHAR, column_name, BUFFER_SIZE},
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(TABLE_BIND_COLUMNS));

  const string PK_QUERY =
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" +
    TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length()) + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  odbcHandler.ExecQuery(PK_QUERY);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(string(column_name), UNIQUE_COLUMN_NAME);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_OF_INSERTED);

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_INSERTED; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (INSERTED_VALUES[i] != "NULL"){
      ASSERT_EQ(data_len, INSERTED_VALUES[i].length());
      ASSERT_EQ(string(data), INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();

  // Attempt to insert values that violates unique constraint and assert that they all fail
  // ie insert the same values from earlier
  for (int i = NUM_OF_INSERTED; i < 2 * NUM_OF_INSERTED; i++) {
    string insert_string = "(" + std::to_string(i) + ",\'" + INSERTED_VALUES[i - NUM_OF_INSERTED] + "\')";

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

TEST_F(PSQL_DataTypes_SmallDateTime, Table_Composite_Keys) {
  vector<pair<string, string>> TABLE_COLUMNS = {
    {COL1_NAME, "INT"},
    {COL2_NAME, DATATYPE_NAME}
  };
  const string PKTABLE_NAME = TABLE_NAME.substr(TABLE_NAME.find('.') + 1, TABLE_NAME.length());
  const string SCHEMA_NAME = TABLE_NAME.substr(0, TABLE_NAME.find('.'));

  const vector<string> PK_COLUMNS = {
    COL1_NAME,
    COL2_NAME
  };

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < PK_COLUMNS.size(); i++) {
    table_constraints += comma + PK_COLUMNS[i];
    comma = ",";
  }
  table_constraints += ")";

  const int PK_BYTES_EXPECTED = 4;

  int pk;
  char data[BUFFER_SIZE];
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  const vector<string> INSERTED_VALUES = {
    "1900-01-01 00:00:00",
    "2000-05-20 23:59:00"
  };
  const int NUM_INSERTED = INSERTED_VALUES.size();

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  string insert_string{};
  comma = "";

  for (int i = 0; i < NUM_INSERTED; i++) {
    insert_string += comma + "(" + std::to_string(i) + ",\'" + INSERTED_VALUES[i] + "\')";
    comma = ",";
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS, table_constraints));
  odbcHandler.CloseStmt();

  // Check if composite key still matches after creation
  char table_name[BUFFER_SIZE];
  char column_name[BUFFER_SIZE];
  int key_sq{};
  char pk_name[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int>> CONSTRAINTS_BIND_COLUMNS = {
    {3, SQL_C_CHAR, table_name, BUFFER_SIZE},
    {4, SQL_C_CHAR, column_name, BUFFER_SIZE},
    {5, SQL_C_ULONG, &key_sq, BUFFER_SIZE},
    {6, SQL_C_CHAR, pk_name, BUFFER_SIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(CONSTRAINTS_BIND_COLUMNS));

  rcode = SQLPrimaryKeys(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR *)SCHEMA_NAME.c_str(), SQL_NTS, (SQLCHAR *)PKTABLE_NAME.c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_SUCCESS);

  int curr_sq{0};
  for (auto columnName : PK_COLUMNS) {
    ++curr_sq;
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);

    ASSERT_EQ(string(table_name), PKTABLE_NAME);
    ASSERT_EQ(string(column_name), columnName);
    ASSERT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, NUM_INSERTED);

  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_INSERTED; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (INSERTED_VALUES[i] != "NULL") {
      ASSERT_EQ(data_len, INSERTED_VALUES[i].length());
      ASSERT_EQ(string(data), INSERTED_VALUES[i]);
    }
    else {
      ASSERT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();

  // Attempt to insert values that violates composite constraint and assert that they all fail
  for (int i = 0; i < NUM_INSERTED * 2; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + INSERTED_VALUES[i % NUM_INSERTED] + ")";
    comma = ",";
  }

  rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
  ASSERT_EQ(rcode, SQL_ERROR);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}
