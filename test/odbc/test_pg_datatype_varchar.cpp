#include <gtest/gtest.h>
#include <sqlext.h>
#include "odbc_handler.h"
#include "query_generator.h"

using std::pair;

const string TABLE_NAME = "master_dbo.varchar_table";
const string DATATYPE = "sys.varchar";
const int NUM_COLS = 4;
const string COL_NAMES[NUM_COLS] = {"pk", "varchar_1", "varchar_4000", "varchar_20"};
const int COL_LENGTH[NUM_COLS] = {10, 1, 4000, 20};

const string COL_TYPES[NUM_COLS] = {
  DATATYPE + "(" + std::to_string(COL_LENGTH[0]) + ")",
  DATATYPE + "(" + std::to_string(COL_LENGTH[1]) + ")",
  DATATYPE + "(" + std::to_string(COL_LENGTH[2]) + ")",
  DATATYPE + "(" + std::to_string(COL_LENGTH[3]) + ")"
};

vector<pair<string, string>> TABLE_COLUMNS = {
  {COL_NAMES[0], COL_TYPES[0] + " PRIMARY KEY"},
  {COL_NAMES[1], COL_TYPES[1]},
  {COL_NAMES[2], COL_TYPES[2]},
  {COL_NAMES[3], COL_TYPES[3]}
};

class PSQL_DataTypes_Bigint : public testing::Test{

  void SetUp() override {
  }

  void TearDown() override {

    OdbcHandler test_cleanup;
    test_cleanup.ConnectAndExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
  }
};

// helper function to convert string to equivalent C version of big int (long long int)
long long int StringToBigInt(const string &value) {
  return strtoll(value.c_str(), NULL, 10);
}

TEST_F(PSQL_DataTypes_Bigint, ColAttributes) {

  const int LENGTH_EXPECTED = 10;
  const int PRECISION_EXPECTED = 0;
  const int SCALE_EXPECTED = 0;
  const string NAME_EXPECTED = "unknown";
  const string PREFIX_EXPECTED = "'";
  const string SUFFIX_EXPECTED = "'";
  
  const int BUFFER_SIZE = 256;
  char name[BUFFER_SIZE];
  char suffix[BUFFER_SIZE];
  char prefix[BUFFER_SIZE];
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN is_case_sensitive;

  RETCODE rcode;
  OdbcHandler odbcHandler;

  // Create a table with columns defined with the specific datatype being tested. 
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
  odbcHandler.CloseStmt();

  // Select * From Table to ensure that it exists
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));

  for (int i = 1; i <= NUM_COLS; i++) {

    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(length, COL_LENGTH[i-1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(precision, PRECISION_EXPECTED);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(scale, SCALE_EXPECTED);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), NAME_EXPECTED);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_CASE_SENSITIVE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &is_case_sensitive); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(is_case_sensitive, SQL_FALSE);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_PREFIX, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL); 
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(string(name), PREFIX_EXPECTED);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_SUFFIX, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    ASSERT_EQ(rcode, SQL_SUCCESS); 
    ASSERT_EQ(string(name), SUFFIX_EXPECTED);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

}

// TEST_F(PSQL_DataTypes_Bigint, Insertion_Success) {

//   const int BYTES_EXPECTED = 8;

//   long long int pk;
//   long long int data;
//   SQLLEN pk_len;
//   SQLLEN data_len;
//   SQLLEN affected_rows;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector <string> valid_inserted_values = {
//     "-9223372036854775808",
//     "9223372036854775807",
//     "3",
//     "NULL"
//   };

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
//     {1, SQL_C_SBIGINT, &pk, 0, &pk_len},
//     {2, SQL_C_SBIGINT, &data, 0,  &data_len}
//   };

//   string insert_string{}; 
//   string comma{};
  
//   for (int i = 0; i< valid_inserted_values.size(); ++i) {
//     insert_string += comma + "(" + std::to_string(i) + "," + valid_inserted_values[i] + ")";
//     comma = ",";
//   }

//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table and assert affected rows
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
 
//   rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, valid_inserted_values.size());
  
//   odbcHandler.CloseStmt();

//   // Select all from the tables and assert that the following attributes of the type is correct:
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));

//   // Make sure inserted values are correct
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   for (int i = 0; i < valid_inserted_values.size(); ++i) {
    
//     rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
//     ASSERT_EQ(rcode, SQL_SUCCESS);
//     ASSERT_EQ(pk_len, BYTES_EXPECTED);
//     ASSERT_EQ(pk, i);

//     if (valid_inserted_values[i] != "NULL")
//     {
//       ASSERT_EQ(data_len, BYTES_EXPECTED);
//       ASSERT_EQ(data, StringToBigInt(valid_inserted_values[i]));
//     }
//     else 
//       ASSERT_EQ(data_len, SQL_NULL_DATA);
//   }

//   // Assert that there is no more data
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
//   odbcHandler.CloseStmt();

// }

// TEST_F(PSQL_DataTypes_Bigint, Insertion_Fail) {

//   const int BYTES_EXPECTED = 8;

//   long long int pk;
//   long long int data;
//   SQLLEN pk_len;
//   SQLLEN data_len;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector <string> invalid_inserted_values = {
//     "-9223372036854775809",
//     "9223372036854775808",
//   };

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
//     {1, SQL_C_SBIGINT, &pk, 0, &pk_len},
//     {2, SQL_C_SBIGINT, &data, 0,  &data_len}
//   };

//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Attempt to insert values that are out of range and assert that they all fail
//   for (int i = 0; i < invalid_inserted_values.size(); i++) {

//     string insert_string = "(" + std::to_string(i) + "," + invalid_inserted_values[i] + ")";

//     rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) InsertStatement(TABLE_NAME, insert_string).c_str(), SQL_NTS);
//     ASSERT_EQ(rcode, SQL_ERROR);
//   }

//   // Select all from the tables and assert that nothing was inserted
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
// }

// TEST_F(PSQL_DataTypes_Bigint, Update_Success) {

//   const string PK_INSERTED = "1";
//   const string DATA_INSERTED = "1";
//   const string DATA_UPDATED_VALUE = "5";

//   const string INSERT_STRING = "(" + PK_INSERTED + "," + DATA_INSERTED + ")";
//   const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + PK_INSERTED;

//   const int BYTES_EXPECTED = 8;
//   const int AFFECTED_ROWS_EXPECTED =1;

//   long long int pk;
//   long long int data;
//   SQLLEN pk_len;
//   SQLLEN data_len;
//   SQLLEN affected_rows;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
//     {1, SQL_C_SBIGINT, &pk, 0, &pk_len},
//     {2, SQL_C_SBIGINT, &data, 0,  &data_len}
//   };
  
//   vector<pair<string, string>> update_col = {
//     {COL2_NAME, DATA_UPDATED_VALUE}
//   };

//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table using the correct ODBC data type mapping.
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, INSERT_STRING));
//   odbcHandler.CloseStmt();

//   // Bind Columns
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   // Assert that value is inserted properly
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(pk_len, BYTES_EXPECTED);
//   ASSERT_EQ(pk, StringToBigInt(PK_INSERTED));
//   ASSERT_EQ(data_len, BYTES_EXPECTED);
//   ASSERT_EQ(data, StringToBigInt(DATA_INSERTED));

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
//   odbcHandler.CloseStmt();

//   // Update value
//   odbcHandler.ExecQuery(UpdateTableStatement(TABLE_NAME, update_col, UPDATE_WHERE_CLAUSE));

//   rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(affected_rows, AFFECTED_ROWS_EXPECTED);

//   odbcHandler.CloseStmt();

//   // Assert that updated value is present
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());

//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(pk_len, BYTES_EXPECTED);
//   ASSERT_EQ(pk, StringToBigInt(PK_INSERTED));
//   ASSERT_EQ(data_len, BYTES_EXPECTED);
//   ASSERT_EQ(data, StringToBigInt(DATA_UPDATED_VALUE));

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
// }

// TEST_F(PSQL_DataTypes_Bigint, Update_Fail) {

//   const string PK_INSERTED = "1";
//   const string DATA_INSERTED = "1";
//   const string DATA_UPDATED_VALUE = "9223372036854775808";

//   const string INSERT_STRING = "(" + PK_INSERTED + "," + DATA_INSERTED + ")";
//   const string UPDATE_WHERE_CLAUSE = COL1_NAME + " = " + PK_INSERTED;

//   const int BYTES_EXPECTED = 8;

//   long long int pk;
//   long long int data;
//   SQLLEN pk_len;
//   SQLLEN data_len;

//   RETCODE rcode;
//   OdbcHandler odbcHandler;

//   vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {
//     {1, SQL_C_SBIGINT, &pk, 0, &pk_len},
//     {2, SQL_C_SBIGINT, &data, 0,  &data_len}
//   };
  
//   vector<pair<string, string>> update_col = {
//     {COL2_NAME, DATA_UPDATED_VALUE}
//   };

//   odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, TABLE_COLUMNS));
//   odbcHandler.CloseStmt();

//   // Insert valid values into the table using the correct ODBC data type mapping.
//   odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, INSERT_STRING));
//   odbcHandler.CloseStmt();

//   // Bind Columns
//   ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

//   // Assert that value is inserted properly
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(pk_len, BYTES_EXPECTED);
//   ASSERT_EQ(pk, StringToBigInt(PK_INSERTED));
//   ASSERT_EQ(data_len, BYTES_EXPECTED);
//   ASSERT_EQ(data, StringToBigInt(DATA_INSERTED));

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
//   odbcHandler.CloseStmt();

//   // Update value and assert an error is present
//   rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR*) UpdateTableStatement(TABLE_NAME, update_col, UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
//   ASSERT_EQ(rcode, SQL_ERROR);
//   odbcHandler.CloseStmt();

//   // Assert that no values changed
//   odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));
//   rcode = SQLFetch(odbcHandler.GetStatementHandle());

//   ASSERT_EQ(rcode, SQL_SUCCESS);
//   ASSERT_EQ(pk_len, BYTES_EXPECTED);
//   ASSERT_EQ(pk, StringToBigInt(PK_INSERTED));
//   ASSERT_EQ(data_len, BYTES_EXPECTED);
//   ASSERT_EQ(data, StringToBigInt(DATA_INSERTED));

//   rcode = SQLFetch(odbcHandler.GetStatementHandle());
//   ASSERT_EQ(rcode, SQL_NO_DATA);
// }