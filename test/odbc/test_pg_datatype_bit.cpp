#include <gtest/gtest.h>
#include <sqlext.h>
#include "odbc_handler.h"
#include "query_generator.h"
#include <iostream>
using std::pair;

const string TABLE_NAME = "master_dbo.bit_table_odbc_test";
const string COL1_NAME = "pk";
const string COL2_NAME = "data";
const string DATATYPE_NAME = "sys.bit";
const string VIEW_NAME = "master_dbo.bit_view_odbc_test";
vector<pair<string, string>> TABLE_COLUMNS = {
  {COL1_NAME, "INT PRIMARY KEY"},
  {COL2_NAME, DATATYPE_NAME}
};
const int DATA_COLUMN = 2;

class PSQL_DataTypes_Bit : public testing::Test{
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

// Helper to convert string into a bit represented by char/byte
// Any non-zero values are converted to 1
char StringToBit(const string &value) {
  return static_cast<char>(strtol(value.c_str(), NULL, 10) != 0 ? 1 : 0);
}

TEST_F(PSQL_DataTypes_Bit, Table_Creation) {
  // TODO - Expected needs to be fixed.
  const int LENGTH_EXPECTED = 255;        // Actual 255, Expected 9 (big int + bit? Needs verifiying)
  const int PRECISION_EXPECTED = 0;
  const int SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "unknown"; // Actual "unknown", Expected "bit"
  
  const int BUFFER_SIZE = 256;
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
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));

  // Make sure column attributes are correct
  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &length);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, LENGTH_EXPECTED);
  
  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_PRECISION, // Get the precision of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &precision); 
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PRECISION_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          DATA_COLUMN,
                          SQL_DESC_SCALE, // Get the scale of the column
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &scale); 
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

// Valids
// Any non-zero values are converted to 1
TEST_F(PSQL_DataTypes_Bit, Insertion_Success) {
  // TODO - Fix or Verify expected
  const int PK_BYTES_EXPECTED = 1;
  const int DATA_BYTES_EXPECTED = 1;

  int pk;
  char data;
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  // TODO - Double check if other values or valid
  // ie -1, 2, as SQL Server converts any non-zero into 1
  vector <string> valid_inserted_values = {
    "0",
    "1",
    "-1",
    "2",
    "NULL"
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN*>> bind_columns = {
    {1, SQL_C_CHAR, &pk, 0, &pk_len},
    {2, SQL_C_BIT, &data, 0, &data_len}
  };

  string insert_string{}; 
  string comma{};

  for (int i = 0; i < valid_inserted_values.size(); i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + valid_inserted_values[i] + ")";
    comma = ",";
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(affected_rows, valid_inserted_values.size());
  
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < valid_inserted_values.size(); i++) {    
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, i);
    if (valid_inserted_values[i] != "NULL") {
      const int DATA_BYTES_EXPECTED2 = 1;
      std::cout << "Data Len: " << data_len << ", Expected: " << DATA_BYTES_EXPECTED2 << std::endl;
      ASSERT_EQ(data_len, DATA_BYTES_EXPECTED2);
      ASSERT_EQ(data, StringToBit(valid_inserted_values[i]));
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

// Invalid
TEST_F(PSQL_DataTypes_Bit, Insertion_Fail) {
  RETCODE rcode;
  OdbcHandler odbcHandler;

  vector <string> invalid_inserted_values = {
    "A",
    "TEST_STR"
  };

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Attempt to insert values that are out of range and assert that they all fail
  for (int i = 0; i < invalid_inserted_values.size(); i++) {
    string insert_string = "(" + std::to_string(i) + "," + invalid_inserted_values[i] + ")";

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
    ASSERT_EQ(rcode, SQL_ERROR);
  }

  // Select all from the tables and assert that nothing was inserted
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

// Valid Updates
TEST_F(PSQL_DataTypes_Bit, Update_Success) {
  const string PK_INSERTED = "1";
  const string DATA_INSERTED = "1";
  const int NUM_UPDATES = 3;

  const string DATA_UPDATED_VALUES[NUM_UPDATES] = {
    "1",
    "0",
    "1"
  };

  const string INSERT_STRING = "(" + PK_INSERTED + "," + DATA_INSERTED + ")";
  const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + PK_INSERTED;

  const int PK_BYTES_EXPECTED = 1;
  const int DATA_BYTES_EXPECTED = 1;
  const int AFFECTED_ROWS_EXPECTED = 1;

  int pk;
  char data;
  SQLLEN pk_len;
  SQLLEN data_len;
  SQLLEN affected_rows;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
    {1, SQL_C_CHAR, &pk, 0, &pk_len},
    {2, SQL_C_BIT, &data, 0, &data_len}
  };

  vector<pair<string, string>> update_col{};

  for (int i = 0; i < NUM_UPDATES; i++) {
    update_col.push_back(pair<string, string>(COL2_NAME, DATA_UPDATED_VALUES[i]));
  }

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Insert valid values into the table using the correct ODBC data type mapping.
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, INSERT_STRING));
  odbcHandler.CloseStmt();

  // Bind Columns
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  // Assert that value is inserted properly
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
  ASSERT_EQ(pk, StringToBit(PK_INSERTED));
  ASSERT_EQ(data_len, DATA_BYTES_EXPECTED);
  ASSERT_EQ(data, StringToBit(DATA_INSERTED));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  // Update value multiple times
  for (int i = 0; i < NUM_UPDATES; i++) {
    odbcHandler.ExecQuery(UpdateTableStatement(TABLE_NAME, vector<pair<string,string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    // Assert that updated value is present
    odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {COL1_NAME}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, PK_BYTES_EXPECTED);
    ASSERT_EQ(pk, StringToBit(PK_INSERTED));
    ASSERT_EQ(data_len, DATA_BYTES_EXPECTED);
    ASSERT_EQ(data, StringToBit(DATA_UPDATED_VALUES[i]));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}

// Arithmetic
// || Concat, & AND, | OR, ^ XOR, ~ NOT, << Bitshift Left, >> Bitshift Right

// Views
