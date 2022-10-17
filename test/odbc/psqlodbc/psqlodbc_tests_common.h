#ifndef PSQLODBC_TESTS_COMMON_H
#define PSQLODBC_TESTS_COMMON_H

#include <cmath>
#include <gtest/gtest.h>
#include <sqlext.h>
#include <string>
#include <time.h>
#include <vector>

#include "../src/drivers.h"
#include "../src/odbc_handler.h"
#include "../src/query_generator.h"

using std::vector;
using std::string;
using std::pair;

const int BUFFER_LENGTH = 8192;
const int BUFFER_SIZE = 256;
const int CHARSIZE = 255;
const int INT_BYTES_EXPECTED = 4;

string InitializeInsertString(const vector<string>& insertedValues, bool isNumericInsert);

string createTableConstraint(const string &constraintType, const vector<string> &constrainCols);

void createTable(ServerType serverType, const string &table_name, const vector<pair <string, string>> &columns, const string &constraints = "");

void createView(ServerType serverType, const string &viewName, const string &viewQuery);

void dropObject(ServerType serverType, const string &objectType, const string &objectName);

void insertValuesInTable(ServerType serverType, const string &table_name, const vector<string> &insertedValues, bool isNumericInsert);

void insertValuesInTable(ServerType serverType, const string &tableName, const string &insertString, int numRows);

void verifyValuesInObject(ServerType serverType, const string &objectName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues);

void testCommonColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected);

void testCommonCharColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected, 
  const vector<int> &caseSensitivityExpected, const vector<string> &prefixExpected, const vector<string> &suffixExpected);

void testTableCreationFailure(ServerType serverType, const string &tableName, const vector<vector<pair<string, string>>> &invalidColumns);

void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues);

void testInsertionFailure(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &invalidInsertedValues, bool isNumericInsert);

void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &updatedValues, const vector<string> &expectedUpdatedValues);

void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &expectedInsertedValues, const vector<string> &updatedValues);

void testPrimaryKeys(ServerType serverType, const string &schemaName, const string &pkTableName, const vector<string> &primaryKeyColumns);

void testUniqueConstraint(ServerType serverType, const string &tableName, const vector<string> &uniqueConstraintColumns);

void testComparisonOperators(ServerType serverType, const string &tableName, const string &col1Name, const string &col2Name, 
  const vector<string> &col1Data, const vector<string> &col2Data, const vector<string> &operationsQuery, const vector<vector<char>> &expectedResults);

void testComparisonFunctions(ServerType serverType, const string &tableName, const vector<string> &operationsQuery, const vector<string> &expectedResults);

template <typename T>
void verifyValuesInObject(ServerType serverType, string objectName, string orderByColumnName, int type, T data, 
  int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  
  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ConnectAndExecQuery(SelectStatement(objectName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedLen[i]);
      EXPECT_EQ(data, expectedInsertedValues[i]);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);

  odbcHandler.CloseStmt();
}

template <typename T>
void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, int type, T data, 
  int bufferLen, const vector<string> &insertedValues, const vector<T> &expectedInsertedValues, const vector<long> &expectedLen) {

  insertValuesInTable(serverType, tableName, insertedValues, true);
  verifyValuesInObject(serverType, tableName, orderByColumnName, type, data, bufferLen, insertedValues, expectedInsertedValues, expectedLen);
}

template <typename T>
void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<string> &updatedValues, const vector<T> &expectedUpdatedValues, const vector<long> &expectedUpdatedLen) {
    
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int pkValue = 0;
  const int AFFECTED_ROWS_EXPECTED = 1;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));
  
  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    update_col.push_back(pair<string, string>(colNameToUpdate, updatedValues[i]));
  }

  for (int i = 0; i < updatedValues.size(); i++) {
    // Update value multiple times
    odbcHandler.ExecQuery(UpdateTableStatement(tableName, vector<pair<string, string>>{update_col[i]}, UPDATE_WHERE_CLAUSE));

    rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(affectedRows, AFFECTED_ROWS_EXPECTED);

    odbcHandler.CloseStmt();

    // Assert that updated value is present
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkValue);
    EXPECT_EQ(data_len, expectedUpdatedLen[i]);
    EXPECT_EQ(data, expectedUpdatedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }
}

template <typename T>
void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, const string &colNameToUpdate, int type, 
  T data, int bufferLen, const vector<T> &expectedInsertedValues, const vector<long> &expectedInsertedLen, const vector<string> &updatedValues) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int pkValue = 0;

  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    update_col.push_back(pair<string, string>(colNameToUpdate, updatedValues[i]));
  }

  for (int i = 0; i < updatedValues.size(); i++) {
    // Update value multiple times
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)UpdateTableStatement(tableName, update_col, UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
    odbcHandler.CloseStmt();

    // Assert that no values changed
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkValue);
    EXPECT_EQ(data_len, expectedInsertedLen[i]);
    EXPECT_EQ(data, expectedInsertedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);

    odbcHandler.CloseStmt();
  }
}

template <typename T>
void testComparisonFunctions(ServerType serverType, const string &tableName, int type, const vector<T> &colResults, 
  int bufferLen, vector<string> operationsQuery, const vector<T> &expectedResults, const vector<long> &expectedLen) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    EXPECT_EQ(col_len[i], expectedLen[i]);
    EXPECT_EQ(colResults[i], expectedResults[i]);
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

template <typename T>
void testArithmeticOperators(ServerType serverType, const string &tableName, const string &orderByColumnName, int numOfData, int type, 
  const vector<T> &colResults, int bufferLen, const vector<string> &operationsQuery, const vector<vector<T>> &expectedResults, const vector<long> &expectedLen) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for BIND_COLUMNS
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{orderByColumnName}));
  
  for (int i = 0; i < numOfData; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      EXPECT_EQ(col_len[j], expectedLen[j]);
      EXPECT_EQ(colResults[j], expectedResults[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

#endif
