#ifndef PSQLODBC_TESTS_COMMON_H
#define PSQLODBC_TESTS_COMMON_H

#include <string>
#include <vector>

#include "../src/odbc_handler.h"
#include "../src/query_generator.h"
#include "../src/drivers.h"
#include <gtest/gtest.h>
#include <sqlext.h>

using std::vector;
using std::string;
using std::pair;

string InitializeInsertString(const vector<string> &insertedValues);

void testCommonColumnAttributes(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected);

void testCommonCharColumnAttributes(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<int> lengthExpected, vector<int> precisionExpected, vector<int> scaleExpected, vector<string> nameExpected, vector<int> caseSensitivityExpected, vector<string> prefixExpected, vector<string> suffixExpected);

void testTableCreationFailure(string tableName, vector<vector<pair<string, string>>> invalidColumns);

void testInsertionSuccessChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> insertedValues, vector<string> expectedInsertedValues);

void testInsertionFailure(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> invalidInsertedValues, bool isNumericInsert);

void testUpdateSuccessChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, vector<string> insertedValues, vector<string> expectedInsertedValues, vector<string> updatedValues, vector<string> expectedUpdatedValues);

void testUpdateFailChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, vector<string> insertedValues, vector<string> expectedInsertedValues, vector<string> updatedValues);

void testViewCreationChar(string viewName, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> insertedValues, vector<string> expectedInsertedValues);

void testPrimaryKeysChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string schemaName, string pkTableName, vector<string> primaryKeyColumns, vector<string> insertedValues, vector<string> expectedInsertedValues);

void testUniqueConstraintChar(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, vector<string> uniqueConstraintColumns, vector<string> insertedValues, vector<string> expectedInsertedValues);

void testComparisonOperators(string tableName, vector<pair<string, string>> tableColumns, string col1Name, string col2Name, vector<string> col1Data, vector<string> col2Data, vector<string> operationsQuery, vector<vector<char>> expectedResults);

void testComparisonFunctionsChar(string tableName, vector<pair<string, string>> tableColumns, vector<string> insertedData, vector<string> operationsQuery, vector<string> expectedResults);

template <typename T>
void testInsertionSuccessNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, T data, int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  string comma{};
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
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
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testUpdateSuccessNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, int type, T data, int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedInsertedLen, vector<string> updatedValues, vector<T> expectedUpdatedValues, vector<long> expectedUpdatedLen) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  const int AFFECTED_ROWS_EXPECTED = 1;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  string comma{};
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedLen[i]);
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

  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(0);
  
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
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, 0);
    EXPECT_EQ(data_len, expectedUpdatedLen[i]);
    EXPECT_EQ(data, expectedUpdatedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testUpdateFailNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, string colNameToUpdate, int type, T data, int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedInsertedLen, vector<string> updatedValues) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  string comma{};
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, i);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedLen[i]);
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

  // Prepare update statement.
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(0);
  
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
    EXPECT_EQ(pk_len, 4);
    EXPECT_EQ(pk, 0);
    EXPECT_EQ(data_len, expectedInsertedLen[i]);
    EXPECT_EQ(data, expectedInsertedValues[i]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);

    odbcHandler.CloseStmt();
  }

  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testViewCreationNumeric(string viewName, string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, T data, int bufferLen, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen) {
  
  const string VIEW_QUERY = "SELECT * FROM " + tableName;

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  string comma{};
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Create view
  odbcHandler.ExecQuery(CreateViewStatement(viewName, VIEW_QUERY));
  odbcHandler.CloseStmt();

  // Select all from the view and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(viewName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
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
  odbcHandler.ExecQuery(DropObjectStatement("VIEW", viewName));
  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testPrimaryKeysNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, T data, int bufferLen, string schemaName, string pkTableName, vector<string> primaryKeyColumns, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  
  const int BUFFER_SIZE = 256;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  string table_constraints{"PRIMARY KEY ("};
  string comma{};
  for (int i = 0; i < primaryKeyColumns.size(); i++) {
    table_constraints += comma + primaryKeyColumns[i];
    comma = ",";
  }
  table_constraints += ")";

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, table_constraints));
  odbcHandler.CloseStmt();

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

  rcode = SQLPrimaryKeys(odbcHandler.GetStatementHandle(), NULL, 0, (SQLCHAR *)schemaName.c_str(), SQL_NTS, (SQLCHAR *)pkTableName.c_str(), SQL_NTS);
  EXPECT_EQ(rcode, SQL_SUCCESS);

  int curr_sq{0};
  for (auto columnName : primaryKeyColumns) {
    ++curr_sq;
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    EXPECT_EQ(string(table_name), pkTableName);
    EXPECT_EQ(string(column_name), columnName);
    EXPECT_EQ(key_sq, curr_sq);
  }
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  comma = "";
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
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
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testUniqueConstraintNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, T data, int bufferLen, vector<string> uniqueConstraintColumns, vector<string> insertedValues, vector<T> expectedInsertedValues, vector<long> expectedLen) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));
  const int CHARSIZE = 255;
  char columnName[CHARSIZE];

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;

  string tableConstraints{"UNIQUE("};
  string comma{};
  for (int i = 0; i < uniqueConstraintColumns.size(); i++) {
    tableConstraints += comma + uniqueConstraintColumns[i];
    comma = ",";
  }
  tableConstraints += ")";

  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, tableConstraints));
  odbcHandler.CloseStmt();

  vector<tuple<int, int, SQLPOINTER, int>> constraints_bind_columns = {
    {1, SQL_C_CHAR, columnName, CHARSIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

  const string UNIQUE_QUERY = 
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" + tableName.substr(tableName.find('.') + 1, tableName.length()) + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  
  odbcHandler.ExecQuery(UNIQUE_QUERY);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(string(columnName), uniqueConstraintColumns[0]);
  odbcHandler.CloseStmt();

  const int BUFFER_LENGTH = 8192;
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, type, &data, bufferLen, &data_len}
  };

  string insertString{};
  comma = "";
  for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
      comma = ",";
  }

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, 4);
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
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testComparisonFunctionsNumeric(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, vector<T> colResults, int bufferLen, vector<string> insertedValues, vector<string> operationsQuery, vector<T> expectedResults, vector<long> expectedLen) {
  
  RETCODE rcode;
  SQLLEN affected_rows;
  SQLLEN pk_len;
  SQLLEN data_len;

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const int NUM_OF_DATA = insertedValues.size();
  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

 vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  string insert_string{};
  string comma{};

  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insert_string += comma + "(" + std::to_string(i) + "," + insertedValues[i] + ")";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affected_rows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

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
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

template <typename T>
void testArithmeticOperators(string tableName, vector<pair<string, string>> tableColumns, string orderByColumnName, int type, vector<T> colResults, int bufferLen, vector<string> col1InsertedValues, vector<string> col2InsertedValues, vector<string> operationsQuery, vector<vector<T>> expectedResults, vector<long> expectedLen) {
  
  RETCODE rcode;  
  SQLLEN affected_rows;
  SQLLEN pk_len;
  SQLLEN data_len;

  OdbcHandler odbcHandler(Drivers::GetDriver(ServerType::PSQL));

  const int NUM_OF_DATA = col2InsertedValues.size();
  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> BIND_COLUMNS = {};

  // initialization for BIND_COLUMNS
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, type, (SQLPOINTER)&colResults[i], bufferLen, &col_len[i]);
    BIND_COLUMNS.push_back(tuple_to_insert);
  }

  string insert_string{};
  string comma{};

  // insert_string initialization
  for (int i = 0; i < NUM_OF_DATA; i++) {
    insert_string += comma + "(" + col1InsertedValues[i] + "," + col2InsertedValues[i] + ")";
    comma = ",";
  }

  // Create table
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns));
  odbcHandler.CloseStmt();

  // Insert valid values into the table and assert affected rows
  odbcHandler.ExecQuery(InsertStatement(tableName, insert_string));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affected_rows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affected_rows, NUM_OF_DATA);

  // Make sure inserted values are correct and operations
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  odbcHandler.CloseStmt();
  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{orderByColumnName}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(BIND_COLUMNS));

  for (int i = 0; i < NUM_OF_DATA; i++) {
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
  odbcHandler.ExecQuery(DropObjectStatement("TABLE", tableName));
}

#endif