#include <gtest/gtest.h>
#include <sqlext.h>
#include "odbc_handler.h"
#include "query_generator.h"

using std::pair;

class PSQL_DataTypes : public testing::Test{

};

TEST_F(PSQL_DataTypes, Datatypes_bigint) {

  const string TABLE_NAME = "master_dbo.bigint_table";
  const string COL1_NAME = "pk"; // primary key
  const string COL2_NAME = "data";
  const string DATATYPE_NAME = "sys.bigint";

  const int BYTES_EXPECTED = 8;
  const int NUM_ROWS = 4;
  const int LENGTH_EXPECTED = 20;
  const int PRECISION_EXPECTED = 0;
  const int SCALE_EXPECTED = 0;
  const int BUFFER_SIZE = 256;
  const string NAME_EXPECTED = "int8";
  
  RETCODE rcode;
  OdbcHandler odbcHandler;
  SQLLEN pk_len;
  SQLLEN data_len;
  long long int pk;
  long long int data;
  int length;
  int precision;
  int scale;
  char name[BUFFER_SIZE];
  int strlength;

  vector<pair<string, string>> BIGINT_TABLE_COLUMNS = {
    {COL1_NAME, DATATYPE_NAME + " PRIMARY KEY"},
    {COL2_NAME, DATATYPE_NAME}
  };

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN* >> bind_columns = {

    {1, SQL_C_SBIGINT, &pk, 0, &pk_len},
    {2, SQL_C_SBIGINT, &data, 0,  &data_len}
  };

  vector <string> inserted_values = {
    "-9223372036854775808",
    "9223372036854775807",
    "3",
    "NULL"
  };

  string insert_string = ""; 
  for (int i = 0; i< NUM_ROWS; ++i) {
    insert_string = insert_string + "(" + std::to_string(i) + "," + inserted_values[i] + ")";
    if (i+1 != NUM_ROWS)
      insert_string = insert_string + ", ";
  }

  // Step 1: Create a table with columns defined with the specific datatype being tested. 
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(TABLE_NAME, BIGINT_TABLE_COLUMNS));

  // Step 2: Insert values into the table using the correct ODBC data type mapping.
  odbcHandler.ExecQuery(InsertStatement(TABLE_NAME, insert_string));
  odbcHandler.CloseStmt();

  // Step 3: Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string> {"pk"}));

  // Make sure attributes are correct
  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          2,
                          SQL_DESC_LENGTH,
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &length); // not the same datatype as documented?
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(length, LENGTH_EXPECTED);
  
  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          2,
                          SQL_DESC_PRECISION,
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &precision); 
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(precision, PRECISION_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          2,
                          SQL_DESC_SCALE,
                          NULL,
                          0,
                          NULL,
                          (SQLLEN*) &scale); 
  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(scale, SCALE_EXPECTED);

  rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                          2,
                          SQL_DESC_TYPE_NAME,
                          name,
                          BUFFER_SIZE,
                          (SQLSMALLINT*) &strlength,
                          NULL); 
  ASSERT_EQ(string(name), NAME_EXPECTED);

  // Make sure values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < NUM_ROWS; ++i) {
    
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    ASSERT_EQ(rcode, SQL_SUCCESS);
    ASSERT_EQ(pk_len, BYTES_EXPECTED);
    ASSERT_EQ(pk, i);

    if (inserted_values[i] != "NULL")
    {
      ASSERT_EQ(data_len, BYTES_EXPECTED);
      ASSERT_EQ(data, strtoll(inserted_values[i].c_str(), NULL, 10));
    } 
    else 
      ASSERT_EQ(data_len, SQL_NULL_DATA);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  // Step 4: Update values of one of the rows and assert that the value has been updated by selecting it.
    // TODO: Make an update statement function in query_generator.cpp/.h?
  odbcHandler.ExecQuery("UPDATE " + TABLE_NAME + " SET " + COL2_NAME + " = 100 WHERE " + COL1_NAME + " = 3"); 

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(TABLE_NAME, {"*"}, vector<string>{}, "pk = 3 "));

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());

  ASSERT_EQ(rcode, SQL_SUCCESS);
  ASSERT_EQ(pk_len, BYTES_EXPECTED);
  ASSERT_EQ(pk, 3);
  ASSERT_EQ(data_len, BYTES_EXPECTED);
  ASSERT_EQ(data, (long long int) 100);

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  ASSERT_EQ(rcode, SQL_NO_DATA);

  // Step 5: Cleanup by dropping the table
  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", TABLE_NAME));
}
