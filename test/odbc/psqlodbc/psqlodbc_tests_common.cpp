#include "psqlodbc_tests_common.h"

// helper function to initialize insert string (1, "", "", ""), etc.
string InitializeInsertString(const vector<string>& insertedValues, bool isNumericInsert, int pkStartingValue) {

  string insertString{};
  string comma{};
  if (isNumericInsert) {
    for (int i = 0; i < insertedValues.size(); i++) {
      insertString += comma + "(" + std::to_string(pkStartingValue) + "," + insertedValues[i] + ")";
      comma = ",";
      pkStartingValue = pkStartingValue + 1;
    }
    return insertString;
  }

  for (int i = 0; i < insertedValues.size(); i++) {
    if (insertedValues[i] == "NULL") {
      insertString += comma + "(" + std::to_string(pkStartingValue) + "," + insertedValues[i] + ")";
      comma = ",";
    }
    else {
      insertString += comma + "(" + std::to_string(pkStartingValue) + ",\'" + insertedValues[i] + "\')";
      comma = ",";
    }
    pkStartingValue = pkStartingValue + 1;
  }
  return insertString;
}

string createTableConstraint(const string &constraintType, const vector<string> &constraintCols) {
  
  string tableConstraints{constraintType + "("};
  string comma{};
  for (int i = 0; i < constraintCols.size(); i++) {
    tableConstraints += comma + constraintCols[i];
    comma = ",";
  }
  tableConstraints += ")";

  return tableConstraints;
}

void createTable(ServerType serverType, const string &tableName, const vector<pair <string, string>> &tableColumns, const string &constraints) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.ConnectAndExecQuery(CreateTableStatement(tableName, tableColumns, constraints));
  odbcHandler.CloseStmt();
}

void createView(ServerType serverType, const string &viewName, const string &viewQuery) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.ConnectAndExecQuery(CreateViewStatement(viewName, viewQuery));
  odbcHandler.CloseStmt();
}

void dropObject(ServerType serverType, const string &objectType, const string &objectName) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.ConnectAndExecQuery(DropObjectStatement(objectType, objectName));
}

void insertValuesInTable(ServerType serverType, const string &tableName, const vector<string> &insertedValues, bool isNumericInsert, int pkStartingValue) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));

  RETCODE rcode;
  SQLLEN affectedRows;

  const string insertString = InitializeInsertString(insertedValues, isNumericInsert, pkStartingValue);

  // Insert valid values into the table and assert affected rows
  odbcHandler.ConnectAndExecQuery(InsertStatement(tableName, insertString));
  
  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, insertedValues.size());
  odbcHandler.CloseStmt();
}

void insertValuesInTable(ServerType serverType, const string &tableName, const string &insertString, int numRows) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));

  RETCODE rcode;
  SQLLEN affectedRows;

  // Insert valid values into the table and assert affected rows
  odbcHandler.ConnectAndExecQuery(InsertStatement(tableName, insertString));

  rcode = SQLRowCount(odbcHandler.GetStatementHandle(), &affectedRows);
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(affectedRows, numRows);
  odbcHandler.CloseStmt();
}

void verifyValuesInObject(ServerType serverType, const string &objectName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues, int pkStartingValue, bool caseInsensitive) {
    
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));

  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  // Select all from the tables and assert that the following attributes of the type is correct:
  odbcHandler.ConnectAndExecQuery(SelectStatement(objectName, {"*"}, vector<string> {orderByColumnName}));

  // Make sure inserted values are correct
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertedValues.size(); i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkStartingValue);
    if (insertedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedInsertedValues[i].size());
      string expected = expectedInsertedValues[i];
      if (caseInsensitive) {
        for (auto & c: data) c = tolower(c);
        for (auto & c: expected) c = tolower(c);
      }
      EXPECT_EQ(data, expected);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }
    pkStartingValue = pkStartingValue + 1;
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

void testCommonColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));

  char name[BUFFER_SIZE];

  RETCODE rcode;
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;

  // Select * From Table to ensure that it exists
  odbcHandler.ConnectAndExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  for (int i = 1; i <= numCols; i++) {
    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(length, lengthExpected[i - 1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(precision, precisionExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(scale, scaleExpected[i - 1]);
  }

  for (int i = 1; i <= numCols; i++) {
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), nameExpected[i - 1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

void testCommonCharColumnAttributes(ServerType serverType, const string &tableName, int numCols, const string &orderByColumnName, 
  const vector<int> &lengthExpected, const vector<int> &precisionExpected, const vector<int> &scaleExpected, const vector<string> &nameExpected, 
  const vector<int> &caseSensitivityExpected, const vector<string> &prefixExpected, const vector<string> &suffixExpected) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  
  char name[BUFFER_SIZE];
  
  RETCODE rcode;
  SQLLEN length;
  SQLLEN precision;
  SQLLEN scale;
  SQLLEN isCaseSensitive;

  // Select * From Table to ensure that it exists
  odbcHandler.ConnectAndExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));

  for (int i = 1; i <= numCols; i++) {
    // Make sure column attributes are correct
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LENGTH, // Get the length of the column (size of char in columns)
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &length);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(length, lengthExpected[i - 1]);
    
    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_PRECISION, // Get the precision of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &precision); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(precision, precisionExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_SCALE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &scale); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(scale, scaleExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_TYPE_NAME, // Get the type name of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), nameExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_CASE_SENSITIVE, // Get the scale of the column
                            NULL,
                            0,
                            NULL,
                            (SQLLEN*) &isCaseSensitive); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(isCaseSensitive, caseSensitivityExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_PREFIX, // Get the prefix of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL); 
    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(string(name), prefixExpected[i - 1]);

    rcode = SQLColAttribute(odbcHandler.GetStatementHandle(),
                            i,
                            SQL_DESC_LITERAL_SUFFIX, // Get the suffix character of the column
                            name,
                            BUFFER_SIZE,
                            NULL,
                            NULL);
    EXPECT_EQ(rcode, SQL_SUCCESS); 
    EXPECT_EQ(string(name), suffixExpected[i - 1]);
  }

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
}

void testTableCreationFailure(ServerType serverType, const string &tableName, const vector<vector<pair<string, string>>> &invalidColumns) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  RETCODE rcode;

  odbcHandler.Connect();
  odbcHandler.AllocateStmtHandle();

  for (int i = 0; i < invalidColumns.size(); i++) {
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(),
                        (SQLCHAR*) CreateTableStatement(tableName, invalidColumns[i]).c_str(),
                        SQL_NTS);

    EXPECT_EQ(rcode, SQL_ERROR);
  }
}

void testInsertionSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &insertedValues, const vector<string> &expectedInsertedValues, int pkStartingValue, 
  bool caseInsensitive, bool numericInsert) {

  insertValuesInTable(serverType, tableName, insertedValues, numericInsert, pkStartingValue);
  verifyValuesInObject(serverType, tableName, orderByColumnName, insertedValues, expectedInsertedValues, pkStartingValue, caseInsensitive);
}

void testInsertionFailure(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const vector<string> &invalidInsertedValues, bool isNumericInsert, int pkStartingValue, bool tableRemainsEmpty) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  for (int i = 0; i < invalidInsertedValues.size(); i++) {
    string insertString{};

    if (isNumericInsert) {
      insertString = "(" + std::to_string(pkStartingValue) + "," + invalidInsertedValues[i] + ")";
    }
    else {
      insertString = "(" + std::to_string(pkStartingValue) + ",\'" + invalidInsertedValues[i] + "\')";
    }
    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)InsertStatement(tableName, insertString).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
    pkStartingValue = pkStartingValue + 1;
  }

  // Select all from the table to make sure nothing was inserted
  if (tableRemainsEmpty) {
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string> {orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
  }
  odbcHandler.CloseStmt();
}

void testUpdateSuccess(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &updatedValues, const vector<string> &expectedUpdatedValues, 
  bool caseInsensitive, bool numericUpdate) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);
  
  const int AFFECTED_ROWS_EXPECTED = 1;
  const int pkValue = 0;

  RETCODE rcode;
  SQLLEN affectedRows;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  // Test updating the row. 
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    string valueToUpdate = (numericUpdate || updatedValues[i] == "NULL") ? 
                            updatedValues[i] :  "\'" + updatedValues[i] + "\'";
    update_col.push_back(pair<string, string>(colNameToUpdate, valueToUpdate));
  }

  for (int i = 0; i < updatedValues.size(); i++) {

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

    if (updatedValues[i] != "NULL") {
      EXPECT_EQ(data_len, expectedUpdatedValues[i].size());
      string expected = expectedUpdatedValues[i];
      if (caseInsensitive) {
        for (auto & c: data) c = tolower(c);
        for (auto & c: expected) c = tolower(c);
      }
      EXPECT_EQ(data, expected);
    }
    else {
      EXPECT_EQ(data_len, SQL_NULL_DATA);
    }

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);
    odbcHandler.CloseStmt();
  }
}

void testUpdateFail(ServerType serverType, const string &tableName, const string &orderByColumnName, 
  const string &colNameToUpdate, const vector<string> &expectedInsertedValues, const vector<string> &updatedValues) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int pkValue = 0;

  RETCODE rcode;
  int pk;
  SQLLEN pk_len;
  SQLLEN data_len;
  char data[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {
    {1, SQL_C_LONG, &pk, 0, &pk_len},
    {2, SQL_C_CHAR, &data, BUFFER_SIZE, &data_len}
  };

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  // Test updating the row. 
  const string UPDATE_WHERE_CLAUSE = orderByColumnName + " = " + std::to_string(pkValue);
  
  vector<pair<string, string>> update_col{};
  for (int i = 0; i < updatedValues.size(); i++) {
    string valueToUpdate = "'" + updatedValues[i] + "'";
    update_col.push_back(pair<string, string>(colNameToUpdate, valueToUpdate));
  }

  for (int i = 0; i < updatedValues.size(); i++) {

    rcode = SQLExecDirect(odbcHandler.GetStatementHandle(), (SQLCHAR *)UpdateTableStatement(tableName, update_col, 
      UPDATE_WHERE_CLAUSE).c_str(), SQL_NTS);
    EXPECT_EQ(rcode, SQL_ERROR);
    odbcHandler.CloseStmt();

    // Assert that no values changed
    odbcHandler.ExecQuery(SelectStatement(tableName, {"*"}, vector<string>{orderByColumnName}));
    rcode = SQLFetch(odbcHandler.GetStatementHandle());

    EXPECT_EQ(rcode, SQL_SUCCESS);
    EXPECT_EQ(pk_len, INT_BYTES_EXPECTED);
    EXPECT_EQ(pk, pkValue);
    EXPECT_EQ(data_len, expectedInsertedValues[0].size());
    EXPECT_EQ(data, expectedInsertedValues[0]);

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_NO_DATA);

    odbcHandler.CloseStmt();
  }
}

void testPrimaryKeys(ServerType serverType, const string &schemaName, const string &pkTableName, const vector<string> &primaryKeyColumns) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  char table_name[BUFFER_SIZE];
  char column_name[BUFFER_SIZE];
  int key_sq{};
  char pk_name[BUFFER_SIZE];

  const vector<tuple<int, int, SQLPOINTER, int>> constraints_bind_columns = {
    {3, SQL_C_CHAR, table_name, BUFFER_SIZE},
    {4, SQL_C_CHAR, column_name, BUFFER_SIZE},
    {5, SQL_C_ULONG, &key_sq, BUFFER_SIZE},
    {6, SQL_C_CHAR, pk_name, BUFFER_SIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

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
}

void testUniqueConstraint(ServerType serverType, const string &tableName, const vector<string> &uniqueConstraintColumns) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int CHARSIZE = 255;
  char columnName[CHARSIZE];
  RETCODE rcode;

  const vector<tuple<int, int, SQLPOINTER, int>> constraints_bind_columns = {
    {1, SQL_C_CHAR, columnName, CHARSIZE}
  };
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(constraints_bind_columns));

  const string UNIQUE_QUERY = 
    "SELECT C.COLUMN_NAME FROM "
    "INFORMATION_SCHEMA.TABLE_CONSTRAINTS T "
    "JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C "
    "ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME "
    "WHERE "
    "C.TABLE_NAME='" + tableName + "' "
    "AND T.CONSTRAINT_TYPE='UNIQUE'";
  
  odbcHandler.ExecQuery(UNIQUE_QUERY);
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  EXPECT_EQ(string(columnName), uniqueConstraintColumns[0]);
  odbcHandler.CloseStmt();
}

void testComparisonOperators(ServerType serverType, const string &tableName, const string &col1Name, const string &col2Name, 
  const vector<string> &col1Data, const vector<string> &col2Data, const vector<string> &operationsQuery, const vector<vector<char>> &expectedResults, 
  bool explicitCast, bool explicitQuotes) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  const int BYTES_EXPECTED = 1;
  const int NUM_OF_DATA = col2Data.size();
  const int NUM_OF_OPERATIONS = operationsQuery.size();

  RETCODE rcode;
  SQLLEN affectedRows;

  char colResults[NUM_OF_OPERATIONS];
  SQLLEN colLen[NUM_OF_OPERATIONS];
  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Make sure values with operations performed on them output correct result
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < NUM_OF_DATA; i++) {
    odbcHandler.CloseStmt();
    const string WHERE_STATEMENT = explicitCast ? 
      col1Name + " OPERATOR(sys.=) " + (explicitQuotes ? "\'" + col1Data[i] + "\'" : col1Data[i]) :
      col1Name + "=" + (explicitQuotes ? "\'" + col1Data[i] + "\'" : col1Data[i]);
    odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}, WHERE_STATEMENT));
    ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      EXPECT_EQ(colLen[j], BYTES_EXPECTED);
      EXPECT_EQ(colResults[j], expectedResults[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

void testComparisonFunctions(ServerType serverType, const string &tableName, const vector<string> &operationsQuery, const vector<string> &expectedResults) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;
  SQLLEN affectedRows;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  char colResults[NUM_OF_OPERATIONS][BUFFER_SIZE];
  SQLLEN colLen[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }
  odbcHandler.CloseStmt();

  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_SUCCESS);
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    EXPECT_EQ(colLen[i], expectedResults[i].length());
    EXPECT_EQ(string(colResults[i]), expectedResults[i]);
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

void testStringFunctions(ServerType serverType, const string &tableName, const vector<string> &operationsQuery, const vector<vector<string>> &expectedResults, 
  const int insertionSize, const string &orderByColumnName) {
  
  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;
  SQLLEN affectedRows;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  char colResults[NUM_OF_OPERATIONS][BUFFER_SIZE];
  SQLLEN colLen[NUM_OF_OPERATIONS];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &colLen[i]);
    bind_columns.push_back(tuple_to_insert);
  }
  odbcHandler.CloseStmt();

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{}));
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  for (int i = 0; i < insertionSize; ++i) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle()); // retrieve row-by-row
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) { // retrieve column-by-column
      EXPECT_EQ(colLen[j], expectedResults[j][i].size());
      EXPECT_EQ(string(colResults[j]), expectedResults[j][i]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

void testArithmeticOperators(ServerType serverType, const string &tableName, const string &orderByColumnName, int numOfData,
  const vector<string> &operationsQuery, const vector<vector<string>> &expectedResults) {

  OdbcHandler odbcHandler(Drivers::GetDriver(serverType));
  odbcHandler.Connect(true);

  RETCODE rcode;

  const int NUM_OF_OPERATIONS = operationsQuery.size();
  SQLLEN col_len[NUM_OF_OPERATIONS];
  char colResults[NUM_OF_OPERATIONS][BUFFER_SIZE];

  vector<tuple<int, int, SQLPOINTER, int, SQLLEN *>> bind_columns = {};

  // initialization for bind_columns
  for (int i = 0; i < NUM_OF_OPERATIONS; i++) {
    tuple<int, int, SQLPOINTER, int, SQLLEN *> tuple_to_insert(i + 1, SQL_C_CHAR, (SQLPOINTER)&colResults[i], BUFFER_SIZE, &col_len[i]);
    bind_columns.push_back(tuple_to_insert);
  }

  // Make sure values with operations performed on them output correct result
  ASSERT_NO_FATAL_FAILURE(odbcHandler.BindColumns(bind_columns));

  odbcHandler.ExecQuery(SelectStatement(tableName, operationsQuery, vector<string>{orderByColumnName}));  

  for (int i = 0; i < numOfData; i++) {
    rcode = SQLFetch(odbcHandler.GetStatementHandle());
    EXPECT_EQ(rcode, SQL_SUCCESS);

    for (int j = 0; j < NUM_OF_OPERATIONS; j++) {
      EXPECT_EQ(col_len[j], expectedResults[i][j].size());
      EXPECT_EQ(colResults[j], expectedResults[i][j]);
    }
  }

  // Assert that there is no more data
  rcode = SQLFetch(odbcHandler.GetStatementHandle());
  EXPECT_EQ(rcode, SQL_NO_DATA);
  odbcHandler.CloseStmt();
}

vector<string> getVectorBasedOnColumn(const vector<vector<string>> &vec, const int &col) {
  vector<string> col_vector;

  for (int i = 0; i < vec.size(); i++) {
    col_vector.push_back(vec[i][col]);
  }
  return col_vector;
}

string formatNumericWithScale(string decimal, const int &scale, const bool &is_bbf) {
  size_t dec_pos = decimal.find('.');

  if (dec_pos == std::string::npos) {
    if (scale == 0) { // if no decimal sign and scale is 0, no need to append
      return decimal;
    }
    dec_pos = decimal.size();
    decimal += ".";
  }

  // add extra 0s
  int zeros_needed = scale - (decimal.size() - dec_pos - 1);
  for (int i = 0; i < zeros_needed; i++) {
    decimal += "0";
  }

  if (is_bbf){
    dec_pos = decimal.find('.');

    if ((decimal[dec_pos - 1] == '0' && (dec_pos - 1) == 0) || (decimal[0] == '-' and decimal[1] == '0')){
      decimal.erase(dec_pos - 1, 1);
    }
  }
  return decimal;
}

void formatNumericExpected(vector<string> &vec, const int &scale, const bool &is_bbf) {
  for (int i = 0; i < vec.size(); i++) {
    vec[i] = formatNumericWithScale(vec[i], scale, is_bbf);
  }
}

void compareDoubleEquality(double actual, double expected) {
  std::string errorstmt = "Actual value:" + std::to_string(actual)
          + "\nExpected valuee:" + std::to_string(expected);

  EXPECT_TRUE(std::fabs(actual - expected) < (2 * std::numeric_limits<double>::epsilon())
          ) << errorstmt;    
}
